// Curated suggestion lists for the free-text fields in the Profile screen.
//
// These exist so the user picks a consistent, well-known term rather than
// inventing spellings the backend prompt then has to guess at - "peanut" vs
// "peanuts" vs "pnut" all reach the model differently. Typing anything not on
// the list is still allowed; these are hints, not a whitelist.

const kAllergySuggestions = <String>[
  'Peanuts',
  'Tree nuts',
  'Almonds',
  'Cashews',
  'Walnuts',
  'Milk / dairy',
  'Lactose',
  'Eggs',
  'Wheat',
  'Gluten',
  'Soy',
  'Fish',
  'Shellfish',
  'Prawns',
  'Sesame',
  'Mustard',
  'Celery',
  'Sulphites',
  'Corn',
  'Coconut',
  'Kiwi',
  'Banana',
  'Strawberries',
  'Chickpeas',
  'Lentils',
  'Mushrooms',
];

const kDietarySuggestions = <String>[
  'Vegetarian',
  'Vegan',
  'Eggetarian',
  'Pescatarian',
  'Halal',
  'Kosher',
  'Jain',
  'No beef',
  'No pork',
  'Gluten-free',
  'Dairy-free',
  'Low sodium',
  'Low sugar',
  'Low carb',
  'High protein',
  'High fibre',
  'Low FODMAP',
  'Nut-free',
  'No caffeine',
  'No spicy food',
  'Home-cooked only',
  'Budget-friendly',
  'Quick meals',
];

/// Conditions the meal planner and chat know how to adapt to. Wording matches
/// what the backend prompt expects, which is why the medical-report extractor
/// is told to return terms in this style.
const kConditionSuggestions = <String>[
  'Gestational diabetes',
  'Type 1 diabetes',
  'Type 2 diabetes',
  'Iron deficiency anaemia',
  'Low haemoglobin',
  'Vitamin D deficiency',
  'Vitamin B12 deficiency',
  'Folate deficiency',
  'Hypothyroidism',
  'Hyperthyroidism',
  'PCOS',
  'Pre-eclampsia risk',
  'High blood pressure',
  'Low blood pressure',
  'High cholesterol',
  'Acid reflux',
  'Constipation',
  'Morning sickness',
  'Hyperemesis',
  'Lactose intolerance',
  'Coeliac disease',
  'IBS',
  'Kidney stones',
  'Low platelet count',
  'Underweight',
  'Overweight',
];

/// Case-insensitive "contains" match, with items that *start* with the query
/// ranked first - typing "vit" should surface "Vitamin D deficiency" before
/// "Low vitamin B12".
List<String> filterSuggestions(
  List<String> pool,
  String query, {
  List<String> exclude = const [],
  int limit = 6,
}) {
  final q = query.trim().toLowerCase();
  final taken = exclude.map((e) => e.toLowerCase()).toSet();
  final available = pool.where((s) => !taken.contains(s.toLowerCase()));

  if (q.isEmpty) return available.take(limit).toList();

  final starts = <String>[];
  final contains = <String>[];
  for (final item in available) {
    final lower = item.toLowerCase();
    if (lower.startsWith(q)) {
      starts.add(item);
    } else if (lower.contains(q)) {
      contains.add(item);
    }
  }
  return [...starts, ...contains].take(limit).toList();
}
