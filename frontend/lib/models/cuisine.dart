/// A cuisine the meal planner can cook in. The flag is purely decorative -
/// the [name] is what travels to the backend prompt.
class Cuisine {
  const Cuisine(this.name, this.flag, this.note);

  final String name;
  final String flag;

  /// Short hint shown under the name in the picker.
  final String note;
}

/// Catalogue offered in the profile and meal planner. Ordered roughly by how
/// commonly they come up rather than alphabetically, so the most likely picks
/// are reachable without scrolling.
const kCuisines = <Cuisine>[
  Cuisine('Indian', '🇮🇳', 'Dal, roti, sabzi'),
  Cuisine('Chinese', '🇨🇳', 'Stir-fry, congee'),
  Cuisine('American', '🇺🇸', 'Bowls, bakes, grills'),
  Cuisine('Italian', '🇮🇹', 'Pasta, risotto'),
  Cuisine('Mexican', '🇲🇽', 'Beans, tacos, salsa'),
  Cuisine('Japanese', '🇯🇵', 'Rice, miso, fish'),
  Cuisine('Thai', '🇹🇭', 'Curry, noodles'),
  Cuisine('Mediterranean', '🇬🇷', 'Olive oil, legumes'),
  Cuisine('Middle Eastern', '🇱🇧', 'Hummus, grains'),
  Cuisine('Korean', '🇰🇷', 'Banchan, stews'),
  Cuisine('Vietnamese', '🇻🇳', 'Pho, fresh herbs'),
  Cuisine('French', '🇫🇷', 'Gratins, soups'),
  Cuisine('Spanish', '🇪🇸', 'Tortilla, stews'),
  Cuisine('Ethiopian', '🇪🇹', 'Injera, lentils'),
  Cuisine('Caribbean', '🇯🇲', 'Rice, peas, plantain'),
  Cuisine('Filipino', '🇵🇭', 'Adobo, sinigang'),
];

Cuisine? cuisineByName(String name) {
  for (final c in kCuisines) {
    if (c.name == name) return c;
  }
  return null;
}
