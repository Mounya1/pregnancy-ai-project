// Month-by-month baby reference, the companion to pregnancy_week.dart.
//
// The feeding lines follow AAP/WHO/NHS infant-feeding guidance: breast milk
// or formula only until around 6 months, iron-rich first foods from 6 months,
// no honey and no cow's milk as a main drink before 12 months, and common
// allergens introduced early rather than delayed.
//
// Development is written as "around now", never as a deadline. Babies reach
// these at wildly different times and a month guide is not a screening tool,
// which is why every screen showing this also says so.

class BabyMonth {
  const BabyMonth({
    required this.month,
    required this.headline,
    required this.emoji,
    required this.development,
    required this.feeding,
    required this.parentExperience,
  });

  /// 0 = the first month of life.
  final int month;

  /// Short label for the card, e.g. "Finding their voice".
  final String headline;
  final String emoji;

  final String development;

  /// What goes in - the part this app exists for.
  final String feeding;

  final String parentExperience;

  String get ageLabel {
    if (month == 0) return 'Newborn';
    if (month == 1) return '1 month';
    if (month < 12) return '$month months';
    if (month == 12) return '1 year';
    final years = month ~/ 12;
    final rest = month % 12;
    if (rest == 0) return '$years years';
    return '$years yr $rest mo';
  }

  /// Solids are the dividing line for almost every feeding question.
  bool get onSolids => month >= 6;
}

const kBabyMonths = <BabyMonth>[
  BabyMonth(
    month: 0,
    headline: 'Getting to know you',
    emoji: '👶',
    development:
        'Vision is blurry beyond about 30cm - roughly the distance to your face while feeding. They startle at loud sounds and grip anything pressed into their palm.',
    feeding:
        'Breast milk or formula only, on demand - that is often 8 to 12 times in 24 hours. Breastfed babies need a daily 400 IU vitamin D drop from the first days.',
    parentExperience:
        'Recovery, cluster feeding, and very little sleep. Eat when the baby feeds and keep water within reach - your appetite and thirst will both be higher than you expect.',
  ),
  BabyMonth(
    month: 1,
    headline: 'First real smiles',
    emoji: '🙂',
    development:
        'They start holding your gaze and may give a first social smile. Head control is improving but the neck still needs full support.',
    feeding:
        'Still milk only. Expect a growth spurt around 3 and 6 weeks when feeding suddenly seems constant - that is demand raising supply, not a supply problem.',
    parentExperience:
        'If you are breastfeeding you need roughly 450-500 extra calories a day. Skipping meals to save time is the fastest way to feel awful by evening.',
  ),
  BabyMonth(
    month: 2,
    headline: 'Cooing and tracking',
    emoji: '🗣️',
    development:
        'Cooing and gurgling begin, and their eyes follow a moving object across the middle of their body. Longer stretches of alert, calm attention.',
    feeding:
        'Milk only. Feeds may space out slightly as they get more efficient, so fewer feeds is not automatically less milk.',
    parentExperience:
        'First vaccinations are usually due. Fussiness and a mild temperature for a day afterwards is common and normal.',
  ),
  BabyMonth(
    month: 3,
    headline: 'Hands discovered',
    emoji: '✋',
    development:
        'They find their hands, bring them to their mouth, and push up onto their forearms during tummy time. Laughing out loud starts around now.',
    feeding:
        'Milk only. Hands going in the mouth is exploration, not a sign they are ready for food - readiness is about sitting and head control, which comes later.',
    parentExperience:
        'Night sleep often lengthens a little. Keep iron and B12 up if you are breastfeeding, especially on a vegetarian or vegan diet.',
  ),
  BabyMonth(
    month: 4,
    headline: 'Reaching and rolling',
    emoji: '🤸',
    development:
        'Deliberate reaching for toys, and often the first roll from tummy to back. Everything they catch goes straight to the mouth.',
    feeding:
        'Milk only. There is no benefit to starting solids before around 6 months, and the gut and kidneys are still maturing.',
    parentExperience:
        'The "4 month sleep regression" is a real change in sleep architecture, not a habit you have broken. It passes.',
  ),
  BabyMonth(
    month: 5,
    headline: 'Sitting with support',
    emoji: '🪑',
    development:
        'They sit propped up, hold their head steady, and may pass a toy from hand to hand. Interest in what is on your plate becomes obvious.',
    feeding:
        'Milk only, but this is the month to plan for solids: a high chair, soft-tipped spoons, and a first food chosen for iron.',
    parentExperience:
        'Watch for the three readiness signs before starting: sitting with little support, steady head control, and bringing food to the mouth themselves.',
  ),
  BabyMonth(
    month: 6,
    headline: 'First tastes',
    emoji: '🥣',
    development:
        'Sitting with little or no support, and the tongue-thrust reflex that pushed food out has faded. Babbling gets consonants in it.',
    feeding:
        'Start solids alongside milk, which stays the main nutrition all year. Lead with iron: iron-fortified cereal, pureed meat, lentils, or mashed beans. Offer a few sips of water in an open cup with meals.',
    parentExperience:
        'Introduce common allergens now, one at a time, a few days apart - peanut, egg, dairy, wheat, soy, fish. Early introduction lowers allergy risk rather than raising it.',
  ),
  BabyMonth(
    month: 7,
    headline: 'Two meals a day',
    emoji: '🥕',
    development:
        'Sitting steadily, raking small objects towards themselves, and often rocking on hands and knees.',
    feeding:
        'Move towards two meals a day and widen the range: vegetables, fruit, well-cooked egg, soft-cooked meat, yoghurt. Thicker and lumpier textures, not just smooth puree.',
    parentExperience:
        'Refusing a food is not a verdict. It can take ten or more offers before something is accepted, and pressure makes it take longer.',
  ),
  BabyMonth(
    month: 8,
    headline: 'Pincer grip',
    emoji: '🫐',
    development:
        'Thumb and finger start working together, so small pieces can be picked up. Crawling, shuffling, or rolling to a target.',
    feeding:
        'Three meals a day is typical now. Soft finger foods work well - steamed carrot sticks, banana strips, toast fingers. Nothing round and firm: grapes and cherry tomatoes must be quartered lengthways, and whole nuts are not safe yet.',
    parentExperience:
        'Mess is part of learning to eat. Loading the spoon and letting them bring it to their mouth builds the skill faster than being fed neatly.',
  ),
  BabyMonth(
    month: 9,
    headline: 'Pulling to stand',
    emoji: '🧍',
    development:
        'Pulling up on furniture, cruising sideways along it, and understanding "no" even if they ignore it. Separation anxiety often peaks.',
    feeding:
        'Three meals plus milk feeds. Keep offering iron-rich food at most meals - stores from birth are used up by now, so diet has to cover it.',
    parentExperience:
        'Still no honey and no cow\'s milk as a main drink until 12 months. Cow\'s milk in cooking, and full-fat yoghurt or cheese, are fine.',
  ),
  BabyMonth(
    month: 10,
    headline: 'Feeding themselves',
    emoji: '🍽️',
    development:
        'Handing objects over, waving, and copying what you do. Some first words appear with meaning attached.',
    feeding:
        'Family meals with the salt left out. Chopped rather than pureed, and let them use their hands - self-feeding sets the pace they actually need.',
    parentExperience:
        'Appetite swings day to day. Judge intake across a week, not a meal.',
  ),
  BabyMonth(
    month: 11,
    headline: 'Almost walking',
    emoji: '🚶',
    development:
        'Standing alone briefly, and taking steps while holding on. Fine motor control is good enough for a cup with handles.',
    feeding:
        'Three meals and two snacks alongside milk. Offer water with meals in an open or straw cup rather than juice.',
    parentExperience:
        'Choking risk stays high all year: no whole nuts, popcorn, raw hard carrot, or firm round fruit left whole.',
  ),
  BabyMonth(
    month: 12,
    headline: 'One year old',
    emoji: '🎂',
    development:
        'Many babies walk within a couple of months either side of now. Pointing, and using a few words consistently.',
    feeding:
        'Whole cow\'s milk can become the main drink, about 350-500ml a day - more than that crowds out iron-rich food. Honey is now safe. Food becomes the main nutrition and milk the supplement.',
    parentExperience:
        'If you are still breastfeeding, there is no reason to stop unless you want to. WHO suggests continuing to two years and beyond alongside food.',
  ),
  BabyMonth(
    month: 13,
    headline: 'Toddler appetite',
    emoji: '🍎',
    development:
        'Walking gets steadier and climbing starts. Strong preferences about everything, including food.',
    feeding:
        'Growth slows sharply after the first year, so appetite drops. Eating noticeably less than at 11 months is expected, not a problem.',
    parentExperience:
        'You decide what is offered and when; they decide whether and how much. That split prevents most mealtime battles.',
  ),
  BabyMonth(
    month: 14,
    headline: 'Copying everything',
    emoji: '🪞',
    development:
        'Imitating chores, stacking a couple of blocks, and using a spoon with mixed success.',
    feeding:
        'Three meals and two snacks. Iron and calcium matter most: red meat, beans, lentils, fortified cereal, dairy, or fortified alternatives.',
    parentExperience:
        'Eating the same meal in front of them does more for variety than any amount of encouragement.',
  ),
  BabyMonth(
    month: 15,
    headline: 'First sentences forming',
    emoji: '💬',
    development:
        'Several clear words, and following simple instructions. Running is not far off.',
    feeding:
        'Full-fat dairy until 2 years - fat matters for brain development at this age. Keep portions toddler-sized: roughly a quarter of an adult plate.',
    parentExperience:
        'Grazing all day blunts appetite at meals. Structured snacks work better than an open kitchen.',
  ),
  BabyMonth(
    month: 16,
    headline: 'Picky phase',
    emoji: '🙅',
    development:
        'Independence, strong opinions, and refusing things enjoyed last week. Completely normal and usually temporary.',
    feeding:
        'Keep offering rejected foods without comment. Serve one thing you know they eat alongside whatever is new.',
    parentExperience:
        'Never make a separate meal on demand. It teaches refusal as a strategy and doubles your cooking.',
  ),
  BabyMonth(
    month: 17,
    headline: 'Climbing everything',
    emoji: '🧗',
    development:
        'Stairs with help, kicking a ball, and scribbling. Attention span is still measured in minutes.',
    feeding:
        'Water and milk only as drinks. Juice adds sugar and displaces food; if it is offered at all, keep it small and with a meal.',
    parentExperience:
        'Eating together, even one meal a day, is the single strongest predictor of a varied diet later.',
  ),
  BabyMonth(
    month: 18,
    headline: 'Real conversation',
    emoji: '🗨️',
    development:
        'Vocabulary grows fast, often past twenty words. Feeding themselves with a spoon is mostly successful.',
    feeding:
        'Three meals, two snacks, and about 400ml of milk. Constipation is common - fibre, fruit, and water usually fix it.',
    parentExperience:
        'A vitamin D supplement is still recommended for most toddlers, especially in winter.',
  ),
  BabyMonth(
    month: 19,
    headline: 'Little helper',
    emoji: '🧺',
    development:
        'Wanting to do everything themselves, and frustrated when they cannot. Sorting and matching begins.',
    feeding:
        'Let them help - washing vegetables or stirring. Children eat more of what they had a hand in making.',
    parentExperience:
        'Meals taking longer is a fair trade for them learning to eat without a fight.',
  ),
  BabyMonth(
    month: 20,
    headline: 'Testing limits',
    emoji: '⚡',
    development:
        'Big emotions with a small vocabulary to express them. Tantrums peak somewhere around here.',
    feeding:
        'Do not use pudding as a reward for eating dinner - it makes the vegetable the tax and the sweet the prize.',
    parentExperience:
        'Hunger and tiredness cause most meltdowns. A predictable snack time prevents more than it seems like it should.',
  ),
  BabyMonth(
    month: 21,
    headline: 'Pretend play',
    emoji: '🧸',
    development:
        'Feeding a doll, talking on a toy phone, and short pretend sequences. Jumping with both feet.',
    feeding:
        'Whole-family food with no added salt. Check labels - bread, sauces, and stock cubes carry most of it.',
    parentExperience:
        'Two years of tastes still to build. Variety now is easier than correcting narrowness later.',
  ),
  BabyMonth(
    month: 22,
    headline: 'Growing independence',
    emoji: '🌟',
    development:
        'Two- and three-word phrases, and following instructions with two steps in them.',
    feeding:
        'An open cup instead of a bottle for all drinks by now. Bottles past this age affect teeth and appetite.',
    parentExperience:
        'Brushing twice a day with fluoride toothpaste matters as much as diet for teeth.',
  ),
  BabyMonth(
    month: 23,
    headline: 'Almost two',
    emoji: '🎈',
    development:
        'Running confidently, kicking, and stacking six or more blocks. Language is expanding weekly.',
    feeding:
        'Choking foods still off the list - whole nuts, popcorn, hard raw vegetables, and whole grapes.',
    parentExperience:
        'From 2 years, milk can move to semi-skimmed if they eat well and grow steadily.',
  ),
  BabyMonth(
    month: 24,
    headline: 'Two years old',
    emoji: '🎉',
    development:
        'Short sentences, strong preferences, and real conversation. Growth continues at the slower toddler pace.',
    feeding:
        'Family meals, family food. Fibre and variety matter more than any single nutrient now.',
    parentExperience:
        'You have got them through the fastest growth of their life. The habits set here tend to stick.',
  ),
];

/// Clamped so an out-of-range month still returns something usable.
BabyMonth babyMonthInfo(int month) {
  final clamped = month.clamp(0, kBabyMonths.last.month);
  return kBabyMonths.firstWhere((m) => m.month == clamped);
}
