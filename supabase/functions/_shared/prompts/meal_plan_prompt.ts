export interface MealPlanPromptContext {
  household: {
    name: string;
    adultsCount: number;
    childrenCount: number;
    dietaryRestrictions: string[];
    allergens: string[];
    preferredCuisines: string[];
    maxWeekdayCookingTime: number;
    maxWeekendCookingTime: number;
  };
  pantryItems: Array<{
    name: string;
    quantity?: string;
    location: string;
    expiresInDays?: number;
    isExpiringSoon?: boolean;
  }>;
  candidateRecipes: Array<{
    id: string;
    title: string;
    cuisine?: string;
    diet?: string;
    totalTimeMinutes: number;
    ingredientsSample?: string[];
  }>;
}

export function buildMealPlanPrompt(context: MealPlanPromptContext): string {
  const { household, pantryItems, candidateRecipes } = context;

  const pantrySummary = pantryItems.length > 0
    ? pantryItems
        .map(
          (p) =>
            `- ${p.name} (${p.quantity ?? 'stocked'}, in ${p.location}${
              p.isExpiringSoon ? ' [EXPIRING SOON!]' : ''
            })`
        )
        .join('\n')
    : 'No currently stocked pantry items logged.';

  const candidatesSummary = candidateRecipes
    .map(
      (c) =>
        `ID: "${c.id}" | Title: "${c.title}" | Cuisine: ${c.cuisine ?? 'Indian'} | Diet: ${c.diet ?? 'General'} | Time: ${c.totalTimeMinutes}m`
    )
    .join('\n');

  return `You are PlatePilot's Culinary Planner AI. Your goal is to select an optimal 7-day dinner schedule from the provided candidate recipe list.

### 1. Household Profile
- Household Name: ${household.name}
- Family Composition: ${household.adultsCount} adults, ${household.childrenCount} children
- Dietary Restrictions: ${household.dietaryRestrictions.join(', ') || 'None'}
- Prohibited Allergens (STRICT REJECT): ${household.allergens.join(', ') || 'None'}
- Preferred Cuisines: ${household.preferredCuisines.join(', ') || 'Any Indian'}
- Max Cooking Times: Weekdays <= ${household.maxWeekdayCookingTime} mins, Weekends <= ${household.maxWeekendCookingTime} mins

### 2. Available Pantry Inventory (Prioritize Using These!)
${pantrySummary}

### 3. Candidate Recipes Pool (STRICT CONSTRAINT: ONLY SELECT FROM THIS LIST)
${candidatesSummary}

### 4. Mandatory Instructions
1. STRICT RECIPE IDS: You MUST choose ONLY recipe_id values that exist in the Candidate Recipes Pool above. DO NOT invent or extrapolate IDs.
2. CUISINE & DIETARY ALIGNMENT: Prioritize dishes matching the family's preferred cuisines (${household.preferredCuisines.join(', ')}) and dietary restrictions (${household.dietaryRestrictions.join(', ')}). Never select prohibited allergens.
3. PANTRY OPTIMIZATION: Prefer recipes that consume ingredients from the pantry list, especially items marked [EXPIRING SOON!].
4. TIME CONSTRAINTS: For Monday through Friday, keep preparation times within ${household.maxWeekdayCookingTime} minutes. Saturday and Sunday can be up to ${household.maxWeekendCookingTime} minutes.
5. VARIETY: Do not select the same recipe twice in the week. Provide culinary diversity across the 7 days (Monday through Sunday).
6. EXPLAINABILITY: In each meal's "reason_summary", clearly state why it was selected (e.g., "Continental non-veg dish, fits 25m weekday limit").

Respond strictly in the requested JSON format matching the schema.`;
}

export function buildMealSwapPrompt(
  currentPlanSummary: string,
  targetDay: string,
  targetMealType: string,
  userReason: string,
  candidateRecipes: Array<{
    id: string;
    title: string;
    cuisine?: string;
    diet?: string;
    totalTimeMinutes: number;
  }>
): string {
  const candidatesSummary = candidateRecipes
    .map(
      (c) =>
        `ID: "${c.id}" | Title: "${c.title}" | Cuisine: ${c.cuisine ?? 'Indian'} | Diet: ${c.diet ?? 'General'} | Time: ${c.totalTimeMinutes}m`
    )
    .join('\n');

  return `You are PlatePilot's Culinary Planner AI. The user wants to swap one meal from their existing weekly plan.

### Existing Plan Context
${currentPlanSummary}

### Swap Request
- Target Day: ${targetDay}
- Target Slot: ${targetMealType}
- User Preference/Constraint for Swap: "${userReason}"

### Replacement Candidates Pool (ONLY SELECT FROM THIS LIST)
${candidatesSummary}

### Mandatory Instructions
1. Select exactly ONE replacement recipe from the candidates pool that best satisfies the user request.
2. Maintain weekly balance and avoid picking a dish that is already planned on another day in the existing plan.
3. Return the exact "replacement_recipe_id", "replacement_recipe_title", and an explainable "reason_summary".`;
}
