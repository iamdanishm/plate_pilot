export interface GeminiGenerationOptions {
  model?: string;
  responseSchema?: Record<string, unknown>;
  temperature?: number;
  timeoutMs?: number;
}

export class GeminiService {
  private apiKey: string;
  private defaultModel: string;

  constructor(apiKey?: string, defaultModel?: string) {
    this.apiKey =
      apiKey ||
      Deno.env.get('GEMINI_API_KEY') ||
      '';
    this.defaultModel =
      defaultModel ||
      Deno.env.get('GEMINI_MODEL') ||
      'gemini-3.1-flash-lite';
  }

  async generateStructuredContent<T>(
    prompt: string,
    options: GeminiGenerationOptions = {}
  ): Promise<T> {
    if (!this.apiKey) {
      throw new Error(
        'GEMINI_API_KEY is not configured in Supabase Edge Function environment.'
      );
    }

    const model = options.model || this.defaultModel;
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${this.apiKey}`;

    const generationConfig: Record<string, unknown> = {
      responseMimeType: 'application/json',
      temperature: options.temperature ?? 0.3,
    };

    if (options.responseSchema) {
      generationConfig['responseSchema'] = options.responseSchema;
    }

    const requestBody = {
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }],
        },
      ],
      generationConfig,
    };

    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      options.timeoutMs ?? 20000
    );

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
        signal: controller.signal,
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(
          `Gemini API HTTP Error (${response.status}): ${errorText}`
        );
      }

      const jsonResponse = await response.json();
      const textContent =
        jsonResponse.candidates?.[0]?.content?.parts?.[0]?.text;

      if (!textContent) {
        throw new Error(
          'Gemini returned an empty candidate or missing text response.'
        );
      }

      return JSON.parse(textContent) as T;
    } catch (err: unknown) {
      if (err instanceof DOMException && err.name === 'AbortError') {
        throw new Error('Gemini API call timed out after 20 seconds.');
      }
      throw err;
    } finally {
      clearTimeout(timeout);
    }
  }
}
