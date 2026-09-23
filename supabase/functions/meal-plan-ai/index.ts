import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
import { GeminiService } from '../_shared/gemini_service.ts';
import {
  buildMealPlanPrompt,
  buildMealSwapPrompt,
  MealPlanPromptContext,
} from '../_shared/prompts/meal_plan_prompt.ts';
import {
  mealPlanResponseSchema,
  mealSwapResponseSchema,
} from '../_shared/schemas/meal_plan_schema.ts';

interface RequestBody {
  action: 'generate_plan' | 'swap_meal' | 'adapt_recipe';
  household_id: string;
  target_day?: string;
  target_meal_type?: string;
  swap_reason?: string;
  current_plan_summary?: string;
}

Deno.serve(async (req: Request) => {
  // Handle CORS Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_ANON_KEY')!;
    const authHeader = req.headers.get('Authorization') ?? '';

    // Initialize server-side Supabase Client with service role for trusted data retrieval & secrets access
    const supabaseClient = createClient(supabaseUrl, supabaseServiceKey);

    const body: RequestBody = await req.json();
    const { action, household_id } = body;

    if (!household_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required field: household_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    let apiKey = Deno.env.get('GEMINI_API_KEY');
    let model = Deno.env.get('GEMINI_MODEL');

    if (!apiKey) {
      const { data: dbKey } = await supabaseClient.rpc('get_app_secret', { p_key: 'GEMINI_API_KEY' });
      apiKey = dbKey ?? undefined;
    }
    if (!model) {
      const { data: dbModel } = await supabaseClient.rpc('get_app_secret', { p_key: 'GEMINI_MODEL' });
      model = dbModel ?? 'gemini-3.1-flash-lite';
    }

    const gemini = new GeminiService(apiKey, model);

    // 1. Fetch Household Data including preferences, allergens, and members
    const { data: household, error: hError } = await supabaseClient
      .from('households')
      .select('*, household_preferences(*), household_allergens(*), household_members(*)')
      .eq('id', household_id)
      .single();

    if (hError || !household) {
      return new Response(
        JSON.stringify({ error: `Failed to load household: ${hError?.message ?? 'Not found'}` }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const prefs = household.household_preferences?.[0] ?? {};
    const allergens: string[] = (household.household_allergens ?? [])
      .map((a: any) => a.allergen_id ?? a.custom_allergen)
      .filter(Boolean);

    // Extract members and dietary restrictions
    const members = household.household_members ?? [];
    let adultsCount = 0;
    let childrenCount = 0;
    const dietaryRestrictionsSet = new Set<string>();

    for (const m of members) {
      const name = (m.name ?? '').toLowerCase();
      if (name.startsWith('child')) {
        childrenCount++;
      } else {
        adultsCount++;
      }
      if (Array.isArray(m.dietary_restrictions)) {
        for (const d of m.dietary_restrictions) {
          if (d) dietaryRestrictionsSet.add(d.toLowerCase().trim());
        }
      }
    }
    if (adultsCount === 0) adultsCount = 2;

    const dietaryRestrictions = Array.from(dietaryRestrictionsSet);
    const preferredCuisines: string[] = Array.isArray(prefs.preferred_cuisines) && prefs.preferred_cuisines.length > 0
      ? prefs.preferred_cuisines
      : ['Indian'];
    const maxWeekdayCookingTime: number = prefs.max_weekday_cooking_time_minutes ?? 45;
    const maxWeekendCookingTime: number = prefs.max_weekend_cooking_time_minutes ?? 60;

    // 2. Fetch Active Pantry Items
    const { data: rawPantry } = await supabaseClient
      .from('pantry_items')
      .select('name, quantity, unit, storage_location, expires_at')
      .eq('household_id', household_id);

    const now = new Date();
    const pantryItems = (rawPantry ?? []).map((p: any) => {
      let daysLeft: number | undefined;
      let isExpiringSoon = false;
      if (p.expires_at) {
        const exp = new Date(p.expires_at);
        daysLeft = Math.ceil((exp.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        isExpiringSoon = daysLeft >= 0 && daysLeft <= 3;
      }
      return {
        name: p.name,
        quantity: p.quantity ? `${p.quantity} ${p.unit ?? ''}`.trim() : undefined,
        location: p.storage_location,
        expiresInDays: daysLeft,
        isExpiringSoon,
      };
    });

    // 3. Helper to Fetch Candidates Matching Household Settings
    const getCandidatePool = async (limitCount = 35) => {
      const { data: candidateData, error: candError } = await supabaseClient.rpc(
        'get_meal_plan_candidates',
        { p_household_id: household_id, p_limit: limitCount }
      );

      if (candError || !candidateData || candidateData.length === 0) {
        // Fallback to basic query if RPC fails
        const { data: fallback } = await supabaseClient
          .from('recipes')
          .select('id, title, cuisine, diet, total_time_minutes')
          .eq('language', 'en')
          .limit(limitCount);

        return (fallback ?? []).map((r: any) => ({
          id: r.id,
          title: r.title,
          cuisine: r.cuisine ?? 'Indian',
          diet: r.diet ?? 'General',
          totalTimeMinutes: r.total_time_minutes ?? 30,
        }));
      }

      return (candidateData as any[]).map((r: any) => ({
        id: r.id,
        title: r.title,
        cuisine: r.cuisine ?? 'Indian',
        diet: r.diet ?? 'General',
        totalTimeMinutes: r.total_time_minutes ?? 30,
      }));
    };

    // -------------------------------------------------------------------------
    // ACTION: generate_plan
    // -------------------------------------------------------------------------
    if (action === 'generate_plan') {
      const candidateList = await getCandidatePool(35);

      if (candidateList.length === 0) {
        return new Response(
          JSON.stringify({ error: 'No matching recipe candidates found for household constraints.' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      const candidateMap = new Map<string, any>();
      for (const c of candidateList) {
        candidateMap.set(c.id, c);
      }

      const context: MealPlanPromptContext = {
        household: {
          name: household.name,
          adultsCount,
          childrenCount,
          dietaryRestrictions,
          allergens,
          preferredCuisines,
          maxWeekdayCookingTime,
          maxWeekendCookingTime,
        },
        pantryItems,
        candidateRecipes: candidateList,
      };

      const prompt = buildMealPlanPrompt(context);

      const aiResponse = await gemini.generateStructuredContent<{
        week_summary: string;
        planned_days: Array<{
          day: string;
          meal_type: string;
          recipe_id: string;
          recipe_title: string;
          reason_summary: string;
        }>;
      }>(prompt, {
        responseSchema: mealPlanResponseSchema,
      });

      // RULE 22: Untrusted AI Output Validation
      const validatedDays = aiResponse.planned_days.map((item, idx) => {
        let validId = item.recipe_id;
        let validTitle = item.recipe_title;

        if (!candidateMap.has(validId)) {
          const fallbackCandidate = candidateList[idx % candidateList.length];
          validId = fallbackCandidate.id;
          validTitle = fallbackCandidate.title;
        }

        return {
          day: item.day.toLowerCase(),
          meal_type: item.meal_type.toLowerCase(),
          recipe_id: validId,
          recipe_title: validTitle,
          reason_summary: item.reason_summary,
          servings: adultsCount + childrenCount,
        };
      });

      return new Response(
        JSON.stringify({
          week_summary: aiResponse.week_summary,
          planned_days: validatedDays,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // -------------------------------------------------------------------------
    // ACTION: swap_meal
    // -------------------------------------------------------------------------
    if (action === 'swap_meal') {
      const targetDay = body.target_day ?? 'monday';
      const targetMealType = body.target_meal_type ?? 'dinner';
      const swapReason = body.swap_reason ?? 'Different meal preference';
      const planSummary = body.current_plan_summary ?? 'Current 7-day plan';

      const candidateList = await getCandidatePool(25);

      const prompt = buildMealSwapPrompt(
        planSummary,
        targetDay,
        targetMealType,
        swapReason,
        candidateList
      );

      const swapResponse = await gemini.generateStructuredContent<{
        replacement_recipe_id: string;
        replacement_recipe_title: string;
        reason_summary: string;
      }>(prompt, {
        responseSchema: mealSwapResponseSchema,
      });

      // Verify replacement ID
      const candidateExists = candidateList.some((c: any) => c.id === swapResponse.replacement_recipe_id);
      const finalId = candidateExists
        ? swapResponse.replacement_recipe_id
        : (candidateList[0]?.id ?? swapResponse.replacement_recipe_id);
      const finalTitle = candidateExists
        ? swapResponse.replacement_recipe_title
        : (candidateList[0]?.title ?? swapResponse.replacement_recipe_title);

      return new Response(
        JSON.stringify({
          replacement_recipe_id: finalId,
          replacement_recipe_title: finalTitle,
          reason_summary: swapResponse.reason_summary,
          servings: adultsCount + childrenCount,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ error: `Unsupported action: ${action}` }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Internal Server Error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
