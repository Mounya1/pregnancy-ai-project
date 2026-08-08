import 'shopping_region.dart';
import 'user_profile.dart';

/// What a thing is for, which is also how the list is grouped and tinted.
enum ShopCategory { food, health, gear, clothing, feeding }

String shopCategoryLabel(ShopCategory c) => switch (c) {
      ShopCategory.food => 'Food',
      ShopCategory.health => 'Health',
      ShopCategory.gear => 'Gear',
      ShopCategory.clothing => 'Clothing',
      ShopCategory.feeding => 'Feeding',
    };

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.why,
    required this.category,
    this.essential = false,
  });

  /// Stable across rebuilds of the list - the tick marks are stored against
  /// this, so renaming an item must not silently untick it.
  final String id;

  final String name;

  /// One line on why it is on the list. An unexplained shopping list is just
  /// someone telling you to spend money.
  final String why;

  final ShopCategory category;

  /// Essentials are things it is genuinely awkward to be without. Everything
  /// else is marked optional so the list does not read as forty must-buys.
  final bool essential;
}

class ShoppingSection {
  const ShoppingSection({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<ShoppingItem> items;
}

/// The list for right now: current trimester or baby age, plus whatever is
/// worth buying ahead.
List<ShoppingSection> shoppingFor(UserProfile profile, ShoppingRegion region) {
  final months = profile.babyAgeMonths;
  if (months != null) return _babySections(months, region);

  final week = profile.lifeStage == LifeStage.pregnancy ? profile.pregnancyWeek : null;
  if (week != null) return _pregnancySections(week, region);

  return [_pantrySection(region)];
}

// ---- Pregnancy ----

List<ShoppingSection> _pregnancySections(int week, ShoppingRegion region) {
  final sections = <ShoppingSection>[];

  if (week <= 13) {
    sections.add(const ShoppingSection(
      title: 'First trimester',
      subtitle: 'Getting the basics in place',
      items: [
        ShoppingItem(
          id: 'p_prenatal',
          name: 'Prenatal vitamin with folic acid',
          why: '400mcg folic acid daily until week 12 lowers the risk of neural tube defects.',
          category: ShopCategory.health,
          essential: true,
        ),
        ShoppingItem(
          id: 'p_water_bottle',
          name: 'Large water bottle',
          why: 'Fluid needs rise early, and dehydration makes nausea worse.',
          category: ShopCategory.gear,
          essential: true,
        ),
        ShoppingItem(
          id: 'p_ginger',
          name: 'Ginger tea or ginger sweets',
          why: 'One of the few nausea remedies with evidence behind it.',
          category: ShopCategory.food,
        ),
        ShoppingItem(
          id: 'p_crackers',
          name: 'Dry crackers or plain biscuits',
          why: 'Eating something before getting up blunts morning sickness.',
          category: ShopCategory.food,
        ),
        ShoppingItem(
          id: 'p_bra1',
          name: 'Soft non-wired bra',
          why: 'Breast tenderness starts early and underwire gets uncomfortable fast.',
          category: ShopCategory.clothing,
        ),
      ],
    ));
  } else if (week <= 27) {
    sections.add(const ShoppingSection(
      title: 'Second trimester',
      subtitle: 'The comfortable stretch - use it to get ready',
      items: [
        ShoppingItem(
          id: 'p_maternity_clothes',
          name: 'Maternity clothes or a belly band',
          why: 'A band lets you keep wearing your own trousers a few months longer.',
          category: ShopCategory.clothing,
          essential: true,
        ),
        ShoppingItem(
          id: 'p_iron',
          name: 'Iron supplement (if your doctor advised one)',
          why: 'Iron needs roughly double now. Take it with vitamin C, not with tea or milk.',
          category: ShopCategory.health,
        ),
        ShoppingItem(
          id: 'p_pillow',
          name: 'Pregnancy or body pillow',
          why: 'Side-sleeping gets recommended from around now, and it is hard without support.',
          category: ShopCategory.gear,
        ),
        ShoppingItem(
          id: 'p_moisturiser',
          name: 'Unscented moisturiser',
          why: 'No cream prevents stretch marks, but it does help the itching.',
          category: ShopCategory.health,
        ),
        ShoppingItem(
          id: 'p_shoes',
          name: 'Flat, supportive shoes',
          why: 'Feet swell and the centre of gravity shifts. Heels stop being a good idea.',
          category: ShopCategory.clothing,
        ),
      ],
    ));
  } else {
    sections.add(const ShoppingSection(
      title: 'Third trimester',
      subtitle: 'Buy this before you are too tired to shop',
      items: [
        ShoppingItem(
          id: 'p_nursing_bra',
          name: 'Nursing bras (2-3)',
          why: 'Get fitted after 36 weeks - sizing changes again once milk comes in.',
          category: ShopCategory.clothing,
          essential: true,
        ),
        ShoppingItem(
          id: 'p_maternity_pads',
          name: 'Maternity pads',
          why: 'Bleeding after birth lasts weeks. Ordinary pads are not absorbent enough at first.',
          category: ShopCategory.health,
          essential: true,
        ),
        ShoppingItem(
          id: 'p_nipple_cream',
          name: 'Lanolin or nipple cream',
          why: 'The first week of feeding is when you will want this, not the week after.',
          category: ShopCategory.feeding,
        ),
        ShoppingItem(
          id: 'p_breast_pads',
          name: 'Breast pads',
          why: 'Leaking is normal and starts early.',
          category: ShopCategory.feeding,
        ),
        ShoppingItem(
          id: 'p_snacks',
          name: 'One-handed snacks',
          why: 'Nuts, dates, and bars. You will be feeding at 3am with one arm free.',
          category: ShopCategory.food,
          essential: true,
        ),
      ],
    ));
  }

  if (week >= 30) {
    sections.add(const ShoppingSection(
      title: 'Hospital bag',
      subtitle: 'Packed by 36 weeks - babies do not check the calendar',
      items: [
        ShoppingItem(
          id: 'h_documents',
          name: 'ID, notes, and insurance papers',
          why: 'The one thing nobody can bring you quickly.',
          category: ShopCategory.gear,
          essential: true,
        ),
        ShoppingItem(
          id: 'h_nightwear',
          name: 'Front-opening nightwear',
          why: 'Buttons down the front make feeding and checks far easier.',
          category: ShopCategory.clothing,
          essential: true,
        ),
        ShoppingItem(
          id: 'h_toiletries',
          name: 'Toiletries and a towel',
          why: 'Hospital towels are thin and there are rarely enough.',
          category: ShopCategory.gear,
        ),
        ShoppingItem(
          id: 'h_baby_clothes',
          name: 'Newborn bodysuits and a hat',
          why: 'Two or three - newborns go through outfits faster than you expect.',
          category: ShopCategory.clothing,
          essential: true,
        ),
        ShoppingItem(
          id: 'h_nappies',
          name: 'Newborn nappies and wipes',
          why: 'Some hospitals supply them, most do not. Check yours.',
          category: ShopCategory.gear,
          essential: true,
        ),
        ShoppingItem(
          id: 'h_car_seat',
          name: 'Car seat, fitted and tested',
          why: 'You will not be discharged without one. Practise the straps before the day.',
          category: ShopCategory.gear,
          essential: true,
        ),
        ShoppingItem(
          id: 'h_phone_charger',
          name: 'Long phone charger',
          why: 'The socket is never next to the bed.',
          category: ShopCategory.gear,
        ),
      ],
    ));
  }

  sections.add(_pantrySection(region));
  return sections;
}

// ---- Baby ----

List<ShoppingSection> _babySections(int months, ShoppingRegion region) {
  final sections = <ShoppingSection>[];

  if (months < 3) {
    sections.add(const ShoppingSection(
      title: 'Newborn months',
      subtitle: 'Restocking, mostly',
      items: [
        ShoppingItem(
          id: 'b_nappies',
          name: 'Nappies and wipes',
          why: 'Around 10-12 a day at this age. Buy the next size up before you run out.',
          category: ShopCategory.gear,
          essential: true,
        ),
        ShoppingItem(
          id: 'b_vitd',
          name: 'Vitamin D drops (400 IU)',
          why: 'Recommended daily for every breastfed baby from the first days.',
          category: ShopCategory.health,
          essential: true,
        ),
        ShoppingItem(
          id: 'b_muslins',
          name: 'Muslin cloths (6+)',
          why: 'Burp cloth, sun shade, changing mat, blanket. You will not have too many.',
          category: ShopCategory.gear,
          essential: true,
        ),
        ShoppingItem(
          id: 'b_bodysuits',
          name: 'Bodysuits in the next size up',
          why: 'They grow out of newborn size in weeks, often before it is used.',
          category: ShopCategory.clothing,
        ),
        ShoppingItem(
          id: 'b_nappy_cream',
          name: 'Barrier cream',
          why: 'For nappy rash, which almost every baby gets at some point.',
          category: ShopCategory.health,
        ),
        ShoppingItem(
          id: 'b_thermometer',
          name: 'Digital thermometer',
          why: 'A fever under 3 months needs a doctor the same day - you need to know.',
          category: ShopCategory.health,
          essential: true,
        ),
      ],
    ));
  } else if (months < 6) {
    sections.add(const ShoppingSection(
      title: '3 to 6 months',
      subtitle: 'Getting ready for solids',
      items: [
        ShoppingItem(
          id: 'b_highchair',
          name: 'High chair',
          why: 'Buy it before 6 months. Sitting upright and supported is a safety requirement, not a nicety.',
          category: ShopCategory.feeding,
          essential: true,
        ),
        ShoppingItem(
          id: 'b_spoons',
          name: 'Soft-tipped weaning spoons',
          why: 'Gentle on gums, and small enough to be let go of.',
          category: ShopCategory.feeding,
          essential: true,
        ),
        ShoppingItem(
          id: 'b_bibs',
          name: 'Long-sleeved bibs',
          why: 'Self-feeding is meant to be messy. Full-coverage bibs save the laundry.',
          category: ShopCategory.feeding,
        ),
        ShoppingItem(
          id: 'b_teething',
          name: 'Teething toys',
          why: 'Teeth often start moving now, whether or not any are visible.',
          category: ShopCategory.gear,
        ),
        ShoppingItem(
          id: 'b_sleepsack',
          name: 'Sleep sack',
          why: 'Safer than loose blankets once they start rolling.',
          category: ShopCategory.gear,
        ),
      ],
    ));
  } else if (months < 12) {
    sections.add(const ShoppingSection(
      title: '6 to 12 months',
      subtitle: 'Real food, and the kit to survive it',
      items: [
        ShoppingItem(
          id: 'b_iron_first',
          name: 'Iron-rich first foods',
          why: 'Iron stores from birth run out around 6 months, so diet has to cover it from here.',
          category: ShopCategory.food,
          essential: true,
        ),
        ShoppingItem(
          id: 'b_open_cup',
          name: 'Open or straw cup',
          why: 'Water with meals from 6 months. Skipping the sippy stage is better for teeth and speech.',
          category: ShopCategory.feeding,
          essential: true,
        ),
        ShoppingItem(
          id: 'b_suction_bowl',
          name: 'Suction-base bowls',
          why: 'They will throw the bowl. This buys you a few weeks.',
          category: ShopCategory.feeding,
        ),
        ShoppingItem(
          id: 'b_allergens',
          name: 'Peanut butter and eggs',
          why: 'Introducing common allergens from 6 months lowers allergy risk. Smooth butter thinned with water, never whole nuts.',
          category: ShopCategory.food,
          essential: true,
        ),
        ShoppingItem(
          id: 'b_toothbrush',
          name: 'Baby toothbrush and fluoride paste',
          why: 'Start as soon as the first tooth appears, with a smear of paste.',
          category: ShopCategory.health,
        ),
        ShoppingItem(
          id: 'b_gates',
          name: 'Safety gates and socket covers',
          why: 'Crawling arrives before you feel ready for it.',
          category: ShopCategory.gear,
        ),
      ],
    ));
  } else {
    sections.add(const ShoppingSection(
      title: 'Toddler',
      subtitle: 'Eating what you eat',
      items: [
        ShoppingItem(
          id: 't_milk',
          name: 'Whole milk',
          why: 'From 12 months, about 350-500ml a day. More than that crowds out iron-rich food.',
          category: ShopCategory.food,
          essential: true,
        ),
        ShoppingItem(
          id: 't_plates',
          name: 'Toddler plates and cutlery',
          why: 'Child-sized forks make self-feeding possible rather than frustrating.',
          category: ShopCategory.feeding,
        ),
        ShoppingItem(
          id: 't_snacks',
          name: 'Snack staples',
          why: 'Fruit, yoghurt, cheese, oatcakes. Structured snacks beat grazing all day.',
          category: ShopCategory.food,
        ),
        ShoppingItem(
          id: 't_shoes',
          name: 'First walking shoes',
          why: 'Only once they walk outdoors. Barefoot indoors is better for developing feet.',
          category: ShopCategory.clothing,
        ),
        ShoppingItem(
          id: 't_vitd',
          name: 'Vitamin D drops',
          why: 'Still recommended for most toddlers, especially through winter.',
          category: ShopCategory.health,
        ),
      ],
    ));
  }

  sections.add(_pantrySection(region));
  return sections;
}

// ---- Regional food basket ----

/// The part that genuinely changes with where you are. Nutrient needs are the
/// same everywhere; what is on the shelf and affordable is not.
ShoppingSection _pantrySection(ShoppingRegion region) {
  return ShoppingSection(
    title: 'Food basket near you',
    subtitle: 'Iron, calcium, and protein as sold in ${region.name}',
    items: [
      ShoppingItem(
        id: 'f_iron_${region.code}',
        name: 'Iron: ${region.ironFoods.join(', ')}',
        why: 'Pair with something high in vitamin C. Tea and coffee with the meal block absorption.',
        category: ShopCategory.food,
        essential: true,
      ),
      ShoppingItem(
        id: 'f_calcium_${region.code}',
        name: 'Calcium: ${region.calciumFoods.join(', ')}',
        why: 'Around 1000mg a day through pregnancy and breastfeeding.',
        category: ShopCategory.food,
        essential: true,
      ),
      ShoppingItem(
        id: 'f_protein_${region.code}',
        name: 'Protein: ${region.proteinFoods.join(', ')}',
        why: 'Needs rise by roughly 25g a day in the second half of pregnancy.',
        category: ShopCategory.food,
        essential: true,
      ),
    ],
  );
}
