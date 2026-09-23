export const mealPlanResponseSchema = {
  type: 'OBJECT',
  properties: {
    week_summary: {
      type: 'STRING',
      description:
        'A 1-2 sentence high-level summary explaining how the plan respects family preferences, budget, and available pantry items.',
    },
    planned_days: {
      type: 'ARRAY',
      description: 'The 7-day planned schedule.',
      items: {
        type: 'OBJECT',
        properties: {
          day: {
            type: 'STRING',
            description:
              'Day of the week: monday, tuesday, wednesday, thursday, friday, saturday, or sunday.',
          },
          meal_type: {
            type: 'STRING',
            description: 'Meal slot: breakfast, lunch, or dinner.',
          },
          recipe_id: {
            type: 'STRING',
            description:
              'The exact recipe ID from the supplied candidate recipes list.',
          },
          recipe_title: {
            type: 'STRING',
            description: 'The title of the selected candidate recipe.',
          },
          reason_summary: {
            type: 'STRING',
            description:
              'Short explainable rationale for why this was chosen (e.g. Uses pantry paneer & takes under 30 mins).',
          },
        },
        required: [
          'day',
          'meal_type',
          'recipe_id',
          'recipe_title',
          'reason_summary',
        ],
      },
    },
  },
  required: ['week_summary', 'planned_days'],
};

export const mealSwapResponseSchema = {
  type: 'OBJECT',
  properties: {
    replacement_recipe_id: {
      type: 'STRING',
      description:
        'The exact recipe ID of the replacement meal from the candidate list.',
    },
    replacement_recipe_title: {
      type: 'STRING',
      description: 'Title of the replacement recipe.',
    },
    reason_summary: {
      type: 'STRING',
      description:
        'Explanation of why this replacement satisfies the swap request and fits the week.',
    },
  },
  required: [
    'replacement_recipe_id',
    'replacement_recipe_title',
    'reason_summary',
  ],
};
