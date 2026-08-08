// Where you are shapes what "go buy iron-rich food" actually means. Ragi and
// dates are the answer in Chennai; fortified breakfast cereal is the answer in
// Manchester. The same is true of where you would go to buy it - "drugstore"
// is meaningless in half the world.
//
// Regions are coarse on purpose. A dozen careful groupings beat two hundred
// country entries nobody maintains, and "International" has to stay useful
// rather than being a dumping ground.

class ShoppingRegion {
  const ShoppingRegion({
    required this.code,
    required this.name,
    required this.currency,
    required this.pharmacyTerm,
    required this.babyStoreQuery,
    required this.groceryQuery,
    required this.ironFoods,
    required this.calciumFoods,
    required this.proteinFoods,
  });

  /// ISO 3166-1 alpha-2 where it maps to one country, or a made-up grouping
  /// code ('XX' for International).
  final String code;

  final String name;
  final String currency;

  /// What a pharmacy is called here - the word to search for locally.
  final String pharmacyTerm;

  /// Search strings handed to the maps app. Written as someone here would
  /// type them, which is what makes the results useful.
  final String babyStoreQuery;
  final String groceryQuery;

  /// Locally available, locally affordable sources of the three nutrients
  /// that matter most in pregnancy and early feeding.
  final List<String> ironFoods;
  final List<String> calciumFoods;
  final List<String> proteinFoods;
}

const kShoppingRegions = <ShoppingRegion>[
  ShoppingRegion(
    code: 'IN',
    name: 'India',
    currency: '₹',
    pharmacyTerm: 'medical store',
    babyStoreQuery: 'baby products store',
    groceryQuery: 'supermarket or kirana store',
    ironFoods: ['ragi', 'dates', 'jaggery', 'palak', 'rajma', 'chana', 'poha'],
    calciumFoods: ['curd', 'paneer', 'ragi', 'til (sesame)', 'milk'],
    proteinFoods: ['dal', 'paneer', 'eggs', 'soya chunks', 'curd', 'peanuts'],
  ),
  ShoppingRegion(
    code: 'US',
    name: 'United States',
    currency: '\$',
    pharmacyTerm: 'pharmacy',
    babyStoreQuery: 'baby store',
    groceryQuery: 'grocery store',
    ironFoods: [
      'fortified breakfast cereal',
      'lean beef',
      'spinach',
      'black beans',
      'lentils',
    ],
    calciumFoods: ['milk', 'yogurt', 'cheese', 'fortified orange juice', 'tofu'],
    proteinFoods: ['chicken', 'eggs', 'beans', 'peanut butter', 'greek yogurt'],
  ),
  ShoppingRegion(
    code: 'GB',
    name: 'United Kingdom',
    currency: '£',
    pharmacyTerm: 'chemist',
    babyStoreQuery: 'baby shop',
    groceryQuery: 'supermarket',
    ironFoods: [
      'fortified breakfast cereal',
      'lean red meat',
      'spinach',
      'baked beans',
      'dried apricots',
    ],
    calciumFoods: ['milk', 'yoghurt', 'cheese', 'fortified plant milk', 'sardines'],
    proteinFoods: ['chicken', 'eggs', 'lentils', 'peanut butter', 'cottage cheese'],
  ),
  ShoppingRegion(
    code: 'AE',
    name: 'Gulf / Middle East',
    currency: 'AED',
    pharmacyTerm: 'pharmacy',
    babyStoreQuery: 'baby shop',
    groceryQuery: 'hypermarket',
    ironFoods: ['dates', 'lentils', 'spinach', 'liver', 'fortified cereal', 'tahini'],
    calciumFoods: ['laban', 'labneh', 'cheese', 'milk', 'tahini'],
    proteinFoods: ['chicken', 'eggs', 'hummus', 'lamb', 'fish', 'lentils'],
  ),
  ShoppingRegion(
    code: 'AU',
    name: 'Australia / New Zealand',
    currency: '\$',
    pharmacyTerm: 'chemist',
    babyStoreQuery: 'baby store',
    groceryQuery: 'supermarket',
    ironFoods: ['fortified cereal', 'lean beef', 'spinach', 'lentils', 'dried apricots'],
    calciumFoods: ['milk', 'yoghurt', 'cheese', 'tinned salmon', 'tofu'],
    proteinFoods: ['chicken', 'eggs', 'legumes', 'peanut butter', 'fish'],
  ),
  ShoppingRegion(
    code: 'SG',
    name: 'Southeast Asia',
    currency: '\$',
    pharmacyTerm: 'pharmacy',
    babyStoreQuery: 'baby store',
    groceryQuery: 'supermarket or wet market',
    ironFoods: ['kangkung', 'tofu', 'lean pork', 'clams', 'lentils', 'fortified cereal'],
    calciumFoods: ['tofu', 'milk', 'ikan bilis', 'leafy greens', 'yoghurt'],
    proteinFoods: ['tofu', 'eggs', 'chicken', 'fish', 'tempeh'],
  ),
  ShoppingRegion(
    code: 'XX',
    name: 'International',
    currency: '',
    pharmacyTerm: 'pharmacy',
    babyStoreQuery: 'baby store',
    groceryQuery: 'supermarket',
    ironFoods: ['lentils', 'beans', 'leafy greens', 'red meat', 'fortified cereal'],
    calciumFoods: ['milk', 'yoghurt', 'cheese', 'tofu', 'leafy greens'],
    proteinFoods: ['eggs', 'beans', 'chicken', 'fish', 'nuts'],
  ),
];

ShoppingRegion regionByCode(String? code) => kShoppingRegions.firstWhere(
      (r) => r.code == code,
      orElse: () => kShoppingRegions.last,
    );

/// Best guess from the device's locale, so the first open is already roughly
/// right and picking a region is a correction rather than a setup step.
///
/// [countryCode] comes from the platform locale - never from GPS. Nothing here
/// needs a location permission, and asking for one to decide whether to say
/// "chemist" or "pharmacy" would be indefensible.
ShoppingRegion regionForCountry(String? countryCode) {
  if (countryCode == null || countryCode.isEmpty) return regionByCode('XX');

  const grouped = <String, String>{
    // Exact matches first, then the groupings.
    'IN': 'IN', 'PK': 'IN', 'BD': 'IN', 'LK': 'IN', 'NP': 'IN',
    'US': 'US', 'CA': 'US', 'MX': 'US',
    'GB': 'GB', 'IE': 'GB',
    'AE': 'AE', 'SA': 'AE', 'QA': 'AE', 'KW': 'AE', 'OM': 'AE',
    'BH': 'AE', 'EG': 'AE', 'JO': 'AE',
    'AU': 'AU', 'NZ': 'AU',
    'SG': 'SG', 'MY': 'SG', 'ID': 'SG', 'PH': 'SG', 'TH': 'SG', 'VN': 'SG',
  };

  return regionByCode(grouped[countryCode.toUpperCase()] ?? 'XX');
}
