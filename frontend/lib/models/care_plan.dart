import 'user_profile.dart';

// Things to do, and things to take.
//
// Doses follow ACOG / NHS / WHO public guidance and are written as the
// standard recommendation, never as a prescription. Every entry that depends
// on a blood result or a diagnosis says so in [confirmWithDoctor], and the UI
// shows those differently - the difference between "everyone takes this" and
// "only if your doctor said so" is the whole point of this screen.

// ---- To-do ----

enum CareStage { firstTrimester, secondTrimester, thirdTrimester, newborn, baby }

String careStageLabel(CareStage stage) => switch (stage) {
      CareStage.firstTrimester => 'First trimester',
      CareStage.secondTrimester => 'Second trimester',
      CareStage.thirdTrimester => 'Third trimester',
      CareStage.newborn => 'Newborn',
      CareStage.baby => 'Baby',
    };

class CareTask {
  const CareTask({
    required this.id,
    required this.title,
    required this.detail,
    this.timing = '',
    this.medical = false,
  });

  /// Stable key for the tick mark.
  final String id;

  final String title;
  final String detail;

  /// When it needs doing, e.g. "By week 10". Empty when it is not time-bound.
  final String timing;

  /// True for anything that has to be booked with or asked of a clinician.
  /// These get the doctor tint and sort first.
  final bool medical;
}

class CareSection {
  const CareSection({required this.title, required this.subtitle, required this.tasks});

  final String title;
  final String subtitle;
  final List<CareTask> tasks;
}

const _firstTrimester = CareSection(
  title: 'First trimester',
  subtitle: 'Weeks 1 to 13 - the appointments that set everything up',
  tasks: [
    CareTask(
      id: 't1_book',
      title: 'Book your first antenatal appointment',
      detail: 'The booking appointment covers blood tests, blood pressure, and your history. '
          'Waiting lists are real - book as soon as you know.',
      timing: 'By week 8',
      medical: true,
    ),
    CareTask(
      id: 't1_folic',
      title: 'Start folic acid, 400mcg daily',
      detail: 'Reduces the risk of neural tube defects. Most benefit is in the first weeks, '
          'so start today rather than at your first appointment.',
      timing: 'Now, until week 12',
    ),
    CareTask(
      id: 't1_meds',
      title: 'Check every medicine you take with a doctor',
      detail: 'Including painkillers, herbal remedies, and anything for a long-term condition. '
          'Some are fine, some are not, and stopping the wrong one is also a risk.',
      timing: 'Before changing anything',
      medical: true,
    ),
    CareTask(
      id: 't1_scan',
      title: 'Dating scan',
      detail: 'Confirms how far along you are and how many babies there are. '
          'Your due date usually gets adjusted here.',
      timing: 'Weeks 8 to 14',
      medical: true,
    ),
    CareTask(
      id: 't1_stop',
      title: 'Stop alcohol and smoking',
      detail: 'There is no known safe amount of either in pregnancy. Ask for help if that '
          'is hard - stopping support in pregnancy is free in most places.',
      timing: 'Now',
    ),
    CareTask(
      id: 't1_food',
      title: 'Learn the foods to avoid',
      detail: 'Unpasteurised cheese, undercooked meat and eggs, high-mercury fish, pate, '
          'and liver. Ask this app about anything you are unsure of.',
    ),
    CareTask(
      id: 't1_dental',
      title: 'Book a dental check',
      detail: 'Gums bleed more in pregnancy, and dental care is free or subsidised for '
          'pregnant women in many countries.',
      medical: true,
    ),
    CareTask(
      id: 't1_work',
      title: 'Think about when to tell work',
      detail: 'No rush, but knowing your rights early helps - especially if your job '
          'involves lifting, chemicals, or night shifts.',
    ),
  ],
);

const _secondTrimester = CareSection(
  title: 'Second trimester',
  subtitle: 'Weeks 14 to 27 - the stretch where you can actually get things done',
  tasks: [
    CareTask(
      id: 't2_anomaly',
      title: 'Anomaly scan',
      detail: 'A detailed look at the baby\'s development. This is also usually when the '
          'sex can be seen, if you want to know.',
      timing: 'Weeks 18 to 21',
      medical: true,
    ),
    CareTask(
      id: 't2_glucose',
      title: 'Gestational diabetes test',
      detail: 'Offered to everyone in most places, earlier if you have risk factors. '
          'A positive result is managed, not a disaster.',
      timing: 'Weeks 24 to 28',
      medical: true,
    ),
    CareTask(
      id: 't2_whooping',
      title: 'Whooping cough vaccine',
      detail: 'Given in pregnancy so your antibodies protect the baby in their first '
          'weeks, before their own vaccinations start.',
      timing: 'Weeks 16 to 32',
      medical: true,
    ),
    CareTask(
      id: 't2_classes',
      title: 'Book antenatal classes',
      detail: 'They fill up months ahead. Worth it for the birth information and for '
          'meeting people due at the same time.',
    ),
    CareTask(
      id: 't2_leave',
      title: 'Sort out maternity leave paperwork',
      detail: 'Notice periods vary by country and employer. Doing it now beats doing it '
          'at 36 weeks.',
    ),
    CareTask(
      id: 't2_movements',
      title: 'Get to know the baby\'s movements',
      detail: 'Usually felt from 18 to 24 weeks. There is no set number - what matters '
          'is what is normal for your baby.',
    ),
  ],
);

const _thirdTrimester = CareSection(
  title: 'Third trimester',
  subtitle: 'Weeks 28 to 40 - get ready before you are too tired to',
  tasks: [
    CareTask(
      id: 't3_bag',
      title: 'Pack the hospital bag',
      detail: 'Notes, ID, front-opening nightwear, newborn clothes, nappies, a long '
          'phone charger. The Shop tab has the full list.',
      timing: 'By week 36',
    ),
    CareTask(
      id: 't3_carseat',
      title: 'Fit and test the car seat',
      detail: 'Most hospitals will not discharge you without one. Practise the straps '
          'before the day, not in the car park.',
      timing: 'By week 36',
    ),
    CareTask(
      id: 't3_birthplan',
      title: 'Write a birth plan',
      detail: 'Pain relief, who is with you, feeding intentions. It is a preference '
          'list, not a contract - things change on the day.',
      medical: true,
    ),
    CareTask(
      id: 't3_gbs',
      title: 'Ask about Group B Strep',
      detail: 'Screening practice differs by country. Worth asking what yours does and '
          'what happens if you test positive.',
      timing: 'Weeks 35 to 37',
      medical: true,
    ),
    CareTask(
      id: 't3_kicks',
      title: 'Watch movements every day',
      detail: 'Call the same day if they slow down. Never wait until morning, and never '
          'try cold drinks or sugar to "wake" the baby first.',
      medical: true,
    ),
    CareTask(
      id: 't3_feeding',
      title: 'Decide how you want to feed',
      detail: 'Breast, formula, or both. Knowing what you want makes it easier to ask '
          'for the right help in the first days.',
    ),
  ],
);

const _newborn = CareSection(
  title: 'What your baby needs',
  subtitle: 'The first weeks - the short list that actually matters',
  tasks: [
    CareTask(
      id: 'nb_register',
      title: 'Register the birth',
      detail: 'Deadlines vary by country, usually within 6 weeks. Needed for almost '
          'every other piece of paperwork.',
    ),
    CareTask(
      id: 'nb_check',
      title: 'First newborn examination',
      detail: 'Heart, hips, eyes, and a hearing screen, usually within 72 hours and '
          'again at 6 to 8 weeks.',
      timing: 'First 72 hours',
      medical: true,
    ),
    CareTask(
      id: 'nb_vitd',
      title: 'Start vitamin D drops, 400 IU daily',
      detail: 'Recommended for every breastfed baby from the first days. Formula-fed '
          'babies taking under 1 litre a day usually need them too.',
      timing: 'From day one',
      medical: true,
    ),
    CareTask(
      id: 'nb_feeding',
      title: 'Get feeding checked in person',
      detail: 'Latch, positioning, and weight. One session with a midwife or lactation '
          'consultant in the first week prevents most later problems.',
      timing: 'First week',
      medical: true,
    ),
    CareTask(
      id: 'nb_sleep',
      title: 'Set up a safe sleep space',
      detail: 'On their back, on a firm flat surface, in your room for the first 6 '
          'months. Nothing loose in the cot.',
    ),
    CareTask(
      id: 'nb_vaccines',
      title: 'Book the first vaccinations',
      detail: 'The primary schedule usually starts at 6 to 8 weeks. Your clinic will '
          'have the dates for your country.',
      timing: 'By 8 weeks',
      medical: true,
    ),
    CareTask(
      id: 'nb_weight',
      title: 'Weight and growth checks',
      detail: 'Babies lose weight in the first days and should be back to birth weight '
          'by about two weeks.',
      timing: 'First two weeks',
      medical: true,
    ),
    CareTask(
      id: 'nb_you',
      title: 'Your own postnatal check',
      detail: 'Usually at 6 to 8 weeks. Mental health is part of it - say honestly how '
          'you are, not how you think you should be.',
      timing: '6 to 8 weeks',
      medical: true,
    ),
  ],
);

const _babyOngoing = CareSection(
  title: 'Through the first year',
  subtitle: 'Checkpoints worth not missing',
  tasks: [
    CareTask(
      id: 'b_solids',
      title: 'Start solids around 6 months',
      detail: 'Iron-rich foods first. Sitting up, steady head, and reaching for food '
          'are the signs of readiness - not age alone.',
      timing: 'Around 6 months',
    ),
    CareTask(
      id: 'b_allergens',
      title: 'Introduce common allergens early',
      detail: 'Peanut, egg, dairy, wheat, soy, fish - one at a time from 6 months. '
          'Delaying raises allergy risk rather than lowering it.',
      timing: 'From 6 months',
      medical: true,
    ),
    CareTask(
      id: 'b_teeth',
      title: 'Brush from the first tooth',
      detail: 'Twice a day with a smear of fluoride toothpaste, and a first dental '
          'visit by their first birthday.',
    ),
    CareTask(
      id: 'b_reviews',
      title: 'Keep the development reviews',
      detail: 'Usually around 9 to 12 months. They catch hearing, vision, and '
          'development things that are easiest to help with early.',
      medical: true,
    ),
    CareTask(
      id: 'b_milk',
      title: 'Move to whole cow\'s milk at 12 months',
      detail: 'About 350 to 500ml a day. More than that crowds out iron-rich food.',
      timing: 'From 12 months',
    ),
  ],
);

/// The to-do lists that apply right now, in the order they matter.
List<CareSection> careTasksFor(UserProfile profile) {
  final months = profile.babyAgeMonths;
  if (months != null) {
    return months < 3 ? [_newborn, _babyOngoing] : [_babyOngoing, _newborn];
  }

  if (profile.lifeStage != LifeStage.pregnancy) return const [];

  final week = profile.pregnancyWeek;
  if (week == null) return const [_firstTrimester, _secondTrimester, _thirdTrimester];

  // Current trimester first, then what is coming, then the newborn list once
  // it is close enough to be worth reading.
  if (week <= 13) return const [_firstTrimester, _secondTrimester];
  if (week <= 27) return const [_secondTrimester, _thirdTrimester];
  return const [_thirdTrimester, _newborn];
}

// ---- Supplements ----

class Supplement {
  const Supplement({
    required this.id,
    required this.name,
    required this.dose,
    required this.why,
    required this.when,
    this.foodSources = '',
    this.confirmWithDoctor = false,
    this.warning = '',
  });

  final String id;
  final String name;

  /// The standard public-health recommendation, e.g. "400mcg daily".
  final String dose;

  final String why;

  /// The window it applies to, e.g. "Until week 12".
  final String when;

  /// Where to get it from food, because a supplement is a backstop, not a
  /// replacement for eating.
  final String foodSources;

  /// True when this should only be taken on a clinician's say-so - usually
  /// because the dose depends on a blood result.
  final bool confirmWithDoctor;

  /// Shown in the warning tint. Only used where getting it wrong does harm.
  final String warning;
}

const _pregnancySupplements = <Supplement>[
  Supplement(
    id: 's_folic',
    name: 'Folic acid',
    dose: '400mcg daily',
    why: 'Lowers the risk of neural tube defects such as spina bifida.',
    when: 'From before conception until week 12',
    foodSources: 'Leafy greens, lentils, beans, fortified cereal, oranges',
  ),
  Supplement(
    id: 's_vitd',
    name: 'Vitamin D',
    dose: '10mcg (400 IU) daily',
    why: 'Supports the baby\'s bones and teeth. Most people do not get enough from sunlight alone.',
    when: 'All through pregnancy and breastfeeding',
    foodSources: 'Oily fish, eggs, fortified milk and cereals',
  ),
  Supplement(
    id: 's_omega',
    name: 'Omega-3 (DHA)',
    dose: 'About 200-300mg DHA daily',
    why: 'Builds the baby\'s brain and eyes, most rapidly in the last three months.',
    when: 'Second and third trimester, and while breastfeeding',
    foodSources: 'Salmon, sardines, mackerel, walnuts, chia and flax seeds, algae oil',
    warning: 'Use a fish-oil or algae supplement, never cod liver oil - it is high in '
        'vitamin A, which is unsafe in pregnancy.',
  ),
  Supplement(
    id: 's_iron',
    name: 'Iron',
    dose: 'Only the dose your doctor gives you',
    why: 'Iron needs roughly double in pregnancy, but supplementing without a blood test '
        'can mask other problems and cause constipation for no reason.',
    when: 'If your bloods show you need it',
    foodSources: 'Red meat, lentils, spinach, fortified cereal, dates, tofu',
    confirmWithDoctor: true,
  ),
  Supplement(
    id: 's_iodine',
    name: 'Iodine',
    dose: '150-220mcg daily',
    why: 'Needed for the baby\'s brain development and your thyroid.',
    when: 'Through pregnancy and breastfeeding',
    foodSources: 'Dairy, eggs, white fish, iodised salt, seaweed in small amounts',
    confirmWithDoctor: true,
  ),
  Supplement(
    id: 's_b12',
    name: 'Vitamin B12',
    dose: 'Usually 2.6mcg daily',
    why: 'Only reliably found in animal foods, so a vegetarian or vegan diet needs a '
        'supplement or fortified foods.',
    when: 'If you eat little or no animal food',
    foodSources: 'Fortified plant milks and cereals, nutritional yeast, eggs, dairy',
    confirmWithDoctor: true,
  ),
  Supplement(
    id: 's_calcium',
    name: 'Calcium',
    dose: 'About 1000mg a day, food first',
    why: 'The baby draws calcium from you. Most people can meet this from diet alone.',
    when: 'Through pregnancy and breastfeeding',
    foodSources: 'Milk, yoghurt, cheese, tofu, ragi, sesame, fortified plant milks',
  ),
];

const _babySupplements = <Supplement>[
  Supplement(
    id: 'bs_vitd',
    name: 'Vitamin D drops',
    dose: '400 IU daily',
    why: 'Breast milk does not contain enough vitamin D, whatever the mother takes.',
    when: 'From the first days, all through the first year',
    foodSources: 'Not available from food at this age - the drops are the source',
  ),
  Supplement(
    id: 'bs_iron',
    name: 'Iron',
    dose: 'From food, from around 6 months',
    why: 'The iron stores a baby is born with run out at about 6 months, which is why '
        'first foods should be iron-rich.',
    when: 'From 6 months',
    foodSources: 'Iron-fortified cereal, pureed meat, lentils, mashed beans',
    confirmWithDoctor: true,
  ),
  Supplement(
    id: 'bs_omega',
    name: 'Omega-3 (DHA)',
    dose: 'From breast milk, formula, or food',
    why: 'Brain development continues fast through the first two years.',
    when: 'Ongoing',
    foodSources: 'Breast milk, DHA-fortified formula, and oily fish once on solids',
  ),
];

/// The supplement list for the current stage.
List<Supplement> supplementsFor(UserProfile profile) {
  if (profile.babyAgeMonths != null) return _babySupplements;
  if (profile.lifeStage == LifeStage.general) return const [];
  return _pregnancySupplements;
}

/// Things not to take. Short, because the list of genuinely dangerous
/// supplements is short - and burying it in a long list is how it gets missed.
const kSupplementsToAvoid = <String>[
  'Vitamin A or retinol supplements, and cod liver oil - too much can harm the baby',
  'High-dose anything, unless a doctor prescribed that dose for you',
  'Herbal supplements and "pregnancy teas" that do not list their contents',
];
