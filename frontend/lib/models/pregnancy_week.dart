// Week-by-week pregnancy reference.
//
// Sizes, weights and lengths are the standard population averages used by
// ACOG/NHS-style week guides. They describe a typical pregnancy, not this
// pregnancy - real babies vary widely and only a scan can say anything about
// a specific one, which is why every screen showing these also says so.
//
// Length switches from crown-to-rump to crown-to-heel at week 20, the same
// point clinical charts switch, because before then the legs are curled and a
// full-body measurement is not meaningful.

import 'user_profile.dart' show calendarDaysBetween;

class PregnancyWeek {
  const PregnancyWeek({
    required this.week,
    required this.sizeComparison,
    required this.emoji,
    required this.weightGrams,
    required this.lengthCm,
    required this.babyDevelopment,
    required this.motherExperience,
  });

  final int week;

  /// Everyday object of about the same size, e.g. "a lime".
  final String sizeComparison;
  final String emoji;

  /// Null before there is anything meaningful to weigh or measure.
  final double? weightGrams;
  final double? lengthCm;

  final String babyDevelopment;
  final String motherExperience;

  int get trimester => week <= 13 ? 1 : (week <= 27 ? 2 : 3);

  String get trimesterLabel => switch (trimester) {
        1 => 'First trimester',
        2 => 'Second trimester',
        _ => 'Third trimester',
      };

  /// Crown-to-rump before week 20, crown-to-heel from week 20.
  String get lengthLabel => week < 20 ? 'head to bottom' : 'head to heel';

  String get weightDisplay {
    final grams = weightGrams;
    if (grams == null) return '-';
    if (grams < 1000) return '${grams.toStringAsFixed(grams < 10 ? 1 : 0)}g';
    return '${(grams / 1000).toStringAsFixed(2)}kg';
  }

  String get lengthDisplay =>
      lengthCm == null ? '-' : '${lengthCm!.toStringAsFixed(lengthCm! < 10 ? 1 : 1)}cm';
}

const kPregnancyWeeks = <PregnancyWeek>[
  PregnancyWeek(
    week: 1,
    sizeComparison: 'nothing yet',
    emoji: '🌱',
    weightGrams: null,
    lengthCm: null,
    babyDevelopment:
        'Week 1 is counted from the first day of your last period, so conception has not happened yet. Your body is preparing to release an egg.',
    motherExperience:
        'You are having your period. Nothing feels different yet, but this is the week your due date is counted from.',
  ),
  PregnancyWeek(
    week: 2,
    sizeComparison: 'nothing yet',
    emoji: '🌱',
    weightGrams: null,
    lengthCm: null,
    babyDevelopment:
        'Ovulation happens around the end of this week. If an egg is fertilised, that is the true start of the pregnancy.',
    motherExperience:
        'You may notice ovulation signs - a change in cervical mucus, or a mild ache on one side.',
  ),
  PregnancyWeek(
    week: 3,
    sizeComparison: 'a grain of salt',
    emoji: '🧂',
    weightGrams: null,
    lengthCm: 0.02,
    babyDevelopment:
        'A fertilised egg has become a tiny ball of dividing cells travelling down the fallopian tube toward the uterus.',
    motherExperience:
        'Implantation may cause a little spotting. Most people still have no idea they are pregnant.',
  ),
  PregnancyWeek(
    week: 4,
    sizeComparison: 'a poppy seed',
    emoji: '⚫',
    weightGrams: null,
    lengthCm: 0.1,
    babyDevelopment:
        'The ball of cells settles into the uterine lining and splits into the embryo and the placenta. The neural tube, which becomes the brain and spine, starts to form.',
    motherExperience:
        'A missed period, and the first positive test. Tender breasts and tiredness are common this early.',
  ),
  PregnancyWeek(
    week: 5,
    sizeComparison: 'a sesame seed',
    emoji: '🌰',
    weightGrams: null,
    lengthCm: 0.2,
    babyDevelopment:
        'The heart begins as a simple tube and starts to beat. The neural tube closes along the back.',
    motherExperience:
        'Nausea and a strong sense of smell often begin. Fatigue can be sudden and heavy.',
  ),
  PregnancyWeek(
    week: 6,
    sizeComparison: 'a lentil',
    emoji: '🫘',
    weightGrams: null,
    lengthCm: 0.4,
    babyDevelopment:
        'Dark spots appear where the eyes will be, and small buds mark the future arms and legs. The heartbeat may be visible on an early scan.',
    motherExperience:
        'Morning sickness can arrive at any hour. You may be going to the loo far more often.',
  ),
  PregnancyWeek(
    week: 7,
    sizeComparison: 'a blueberry',
    emoji: '🫐',
    weightGrams: 1,
    lengthCm: 1.0,
    babyDevelopment:
        'The brain is growing fast and the arm buds are lengthening into paddles. The umbilical cord is fully formed.',
    motherExperience:
        'Nausea often peaks around now. Food aversions can be strong and unpredictable.',
  ),
  PregnancyWeek(
    week: 8,
    sizeComparison: 'a raspberry',
    emoji: '🍇',
    weightGrams: 1,
    lengthCm: 1.6,
    babyDevelopment:
        'Fingers and toes are webbed but forming. The tail has almost gone and the face is taking shape.',
    motherExperience:
        'Your waistband may already feel tight - that is bloating rather than the baby.',
  ),
  PregnancyWeek(
    week: 9,
    sizeComparison: 'a grape',
    emoji: '🍇',
    weightGrams: 2,
    lengthCm: 2.3,
    babyDevelopment:
        'The embryo is about 2.3cm and moving gently, exercising new muscles. Eyelids cover the eyes and the nose is protruding. Arms and legs are growing rapidly.',
    motherExperience:
        'Emotions can swing sharply. Your breasts may have gone up a cup size already.',
  ),
  PregnancyWeek(
    week: 10,
    sizeComparison: 'a kumquat',
    emoji: '🍊',
    weightGrams: 4,
    lengthCm: 3.1,
    babyDevelopment:
        'From this week the embryo is called a fetus. Vital organs are formed and starting to function, and tiny nails begin to appear.',
    motherExperience:
        'You may see visible veins on your chest as blood volume rises.',
  ),
  PregnancyWeek(
    week: 11,
    sizeComparison: 'a fig',
    emoji: '🫒',
    weightGrams: 7,
    lengthCm: 4.1,
    babyDevelopment:
        'The head is still about half the total length. Fingers and toes have separated and the baby can open and close their fists.',
    motherExperience:
        'Nausea may begin to ease. Heartburn can take its place.',
  ),
  PregnancyWeek(
    week: 12,
    sizeComparison: 'a lime',
    emoji: '🍋',
    weightGrams: 14,
    lengthCm: 5.4,
    babyDevelopment:
        'Reflexes develop - the baby will squirm if your belly is prodded, though you cannot feel it. Kidneys start producing urine.',
    motherExperience:
        'The first scan usually falls around now. Many people share the news after it.',
  ),
  PregnancyWeek(
    week: 13,
    sizeComparison: 'a lemon',
    emoji: '🍋',
    weightGrams: 23,
    lengthCm: 7.4,
    babyDevelopment:
        'Vocal cords form and the intestines move from the umbilical cord into the abdomen. Fingerprints are forming.',
    motherExperience:
        'The last week of the first trimester. Energy often starts to return.',
  ),
  PregnancyWeek(
    week: 14,
    sizeComparison: 'a peach',
    emoji: '🍑',
    weightGrams: 43,
    lengthCm: 8.7,
    babyDevelopment:
        'The baby can squint, frown and suck their thumb. Fine hair called lanugo covers the body.',
    motherExperience:
        'Welcome to the second trimester, often the easiest stretch. Appetite usually returns.',
  ),
  PregnancyWeek(
    week: 15,
    sizeComparison: 'an apple',
    emoji: '🍎',
    weightGrams: 70,
    lengthCm: 10.1,
    babyDevelopment:
        'The baby is sensing light through closed eyelids, and taste buds are forming.',
    motherExperience:
        'A blocked nose and occasional nosebleeds are common - pregnancy swells the nasal lining.',
  ),
  PregnancyWeek(
    week: 16,
    sizeComparison: 'an avocado',
    emoji: '🥑',
    weightGrams: 100,
    lengthCm: 11.6,
    babyDevelopment:
        'The heart pumps about 25 litres of blood a day. Legs are now longer than the arms.',
    motherExperience:
        'Some people feel the first flutters this week, especially in a second pregnancy.',
  ),
  PregnancyWeek(
    week: 17,
    sizeComparison: 'a pear',
    emoji: '🍐',
    weightGrams: 140,
    lengthCm: 13.0,
    babyDevelopment:
        'Fat stores begin to form under the skin, and the skeleton is hardening from cartilage into bone.',
    motherExperience:
        'Your centre of gravity is shifting - it is easy to feel a little off balance.',
  ),
  PregnancyWeek(
    week: 18,
    sizeComparison: 'a bell pepper',
    emoji: '🫑',
    weightGrams: 190,
    lengthCm: 14.2,
    babyDevelopment:
        'Ears have moved into position and stand out from the head. The baby may now hear muffled sound.',
    motherExperience:
        'Sleeping on your side becomes more comfortable than your back.',
  ),
  PregnancyWeek(
    week: 19,
    sizeComparison: 'a mango',
    emoji: '🥭',
    weightGrams: 240,
    lengthCm: 15.3,
    babyDevelopment:
        'A greasy white coating called vernix now protects the skin from the amniotic fluid.',
    motherExperience:
        'Round ligament pain - a sharp tug low on one side when you move quickly - is common.',
  ),
  PregnancyWeek(
    week: 20,
    sizeComparison: 'a banana',
    emoji: '🍌',
    weightGrams: 300,
    lengthCm: 25.6,
    babyDevelopment:
        'Halfway. From this week length is measured head to heel. The baby is swallowing regularly, which helps the digestive system develop.',
    motherExperience:
        'The anomaly scan usually happens now. Movements are becoming unmistakable.',
  ),
  PregnancyWeek(
    week: 21,
    sizeComparison: 'a carrot',
    emoji: '🥕',
    weightGrams: 360,
    lengthCm: 26.7,
    babyDevelopment:
        'Arms and legs are finally in proportion. The baby is moving with real coordination.',
    motherExperience:
        'Appetite can pick up sharply. Stretch marks may start to appear.',
  ),
  PregnancyWeek(
    week: 22,
    sizeComparison: 'a papaya',
    emoji: '🍈',
    weightGrams: 430,
    lengthCm: 27.8,
    babyDevelopment:
        'Lips, eyelids and eyebrows are more distinct. The eyes are formed though the irises still lack pigment.',
    motherExperience:
        'You may notice swelling in your feet by the end of the day.',
  ),
  PregnancyWeek(
    week: 23,
    sizeComparison: 'a grapefruit',
    emoji: '🍊',
    weightGrams: 501,
    lengthCm: 28.9,
    babyDevelopment:
        'The baby can hear your voice clearly now and may startle at sudden loud noises.',
    motherExperience:
        'Braxton Hicks - painless practice tightenings - may begin.',
  ),
  PregnancyWeek(
    week: 24,
    sizeComparison: 'an ear of corn',
    emoji: '🌽',
    weightGrams: 600,
    lengthCm: 30.0,
    babyDevelopment:
        'The lungs are developing branches and beginning to make surfactant, which will let them inflate at birth. This is the week of viability.',
    motherExperience:
        'Your glucose test is usually around now. Backache is common as the bump grows.',
  ),
  PregnancyWeek(
    week: 25,
    sizeComparison: 'a cauliflower',
    emoji: '🥦',
    weightGrams: 660,
    lengthCm: 34.6,
    babyDevelopment:
        'Hair is growing and has real colour and texture. The baby is putting on baby fat and looking less wrinkled.',
    motherExperience:
        'Heartburn and constipation often intensify. Small frequent meals help.',
  ),
  PregnancyWeek(
    week: 26,
    sizeComparison: 'a head of lettuce',
    emoji: '🥬',
    weightGrams: 760,
    lengthCm: 35.6,
    babyDevelopment:
        'Eyes begin to open for the first time. The baby is inhaling and exhaling amniotic fluid to practise breathing.',
    motherExperience:
        'Rising blood pressure is worth watching - keep antenatal appointments.',
  ),
  PregnancyWeek(
    week: 27,
    sizeComparison: 'a cabbage',
    emoji: '🥬',
    weightGrams: 875,
    lengthCm: 36.6,
    babyDevelopment:
        'The brain is very active and sleep cycles are establishing, including REM sleep. Hiccups are common and you will feel them.',
    motherExperience:
        'The last week of the second trimester. Leg cramps at night are frequent.',
  ),
  PregnancyWeek(
    week: 28,
    sizeComparison: 'an aubergine',
    emoji: '🍆',
    weightGrams: 1005,
    lengthCm: 37.6,
    babyDevelopment:
        'The baby can blink, and eyelashes have grown in. They may turn head-down around this time.',
    motherExperience:
        'Third trimester. Antenatal visits usually become more frequent from here.',
  ),
  PregnancyWeek(
    week: 29,
    sizeComparison: 'a butternut squash',
    emoji: '🎃',
    weightGrams: 1153,
    lengthCm: 38.6,
    babyDevelopment:
        'Muscles and lungs are maturing, and the head is growing to make room for the developing brain.',
    motherExperience:
        'Kicks are strong enough to be visible from the outside. Heartburn may worsen.',
  ),
  PregnancyWeek(
    week: 30,
    sizeComparison: 'a cucumber',
    emoji: '🥒',
    weightGrams: 1319,
    lengthCm: 39.9,
    babyDevelopment:
        'Around a litre and a half of amniotic fluid surrounds the baby, and that will now reduce as they take up more space.',
    motherExperience:
        'Fatigue often returns. Shortness of breath is normal as the uterus presses upward.',
  ),
  PregnancyWeek(
    week: 31,
    sizeComparison: 'a coconut',
    emoji: '🥥',
    weightGrams: 1502,
    lengthCm: 41.1,
    babyDevelopment:
        'The baby can turn their head side to side, and is putting on weight quickly now.',
    motherExperience:
        'Braxton Hicks become more noticeable. Your breasts may leak colostrum.',
  ),
  PregnancyWeek(
    week: 32,
    sizeComparison: 'a squash',
    emoji: '🎃',
    weightGrams: 1702,
    lengthCm: 42.4,
    babyDevelopment:
        'Toenails and fingernails are fully formed, and the fine lanugo hair starts to shed.',
    motherExperience:
        'It gets harder to find a comfortable sleeping position. A pillow between the knees helps.',
  ),
  PregnancyWeek(
    week: 33,
    sizeComparison: 'a pineapple',
    emoji: '🍍',
    weightGrams: 1918,
    lengthCm: 43.7,
    babyDevelopment:
        'The skull bones stay soft and separate so the head can move through the birth canal.',
    motherExperience:
        'Swelling in hands and feet is common. Report sudden or severe swelling.',
  ),
  PregnancyWeek(
    week: 34,
    sizeComparison: 'a cantaloupe',
    emoji: '🍈',
    weightGrams: 2146,
    lengthCm: 45.0,
    babyDevelopment:
        'The central nervous system and lungs are maturing steadily. Babies born now usually do very well.',
    motherExperience:
        'Vision can feel a little blurry - pregnancy hormones reduce tear production.',
  ),
  PregnancyWeek(
    week: 35,
    sizeComparison: 'a honeydew melon',
    emoji: '🍈',
    weightGrams: 2383,
    lengthCm: 46.2,
    babyDevelopment:
        'The kidneys are fully developed and the liver can process some waste products.',
    motherExperience:
        'The bump is high and crowded - small meals are easier than large ones.',
  ),
  PregnancyWeek(
    week: 36,
    sizeComparison: 'a romaine lettuce',
    emoji: '🥬',
    weightGrams: 2622,
    lengthCm: 47.4,
    babyDevelopment:
        'The baby is shedding most of the vernix and lanugo, and swallowing both along with amniotic fluid.',
    motherExperience:
        'The baby may drop lower into your pelvis, easing breathing but increasing pressure below.',
  ),
  PregnancyWeek(
    week: 37,
    sizeComparison: 'a winter melon',
    emoji: '🍈',
    weightGrams: 2859,
    lengthCm: 48.6,
    babyDevelopment:
        'Early term. The baby is practising breathing, sucking and gripping, and is gaining around 200g a week.',
    motherExperience:
        'Nesting energy is common. Keep an eye out for signs of labour.',
  ),
  PregnancyWeek(
    week: 38,
    sizeComparison: 'a leek',
    emoji: '🥬',
    weightGrams: 3083,
    lengthCm: 49.8,
    babyDevelopment:
        'The baby has a firm grasp and their organs are ready for life outside.',
    motherExperience:
        'Pelvic pressure and frequent trips to the loo. Any fluid leak needs a call to your midwife.',
  ),
  PregnancyWeek(
    week: 39,
    sizeComparison: 'a small watermelon',
    emoji: '🍉',
    weightGrams: 3288,
    lengthCm: 50.7,
    babyDevelopment:
        'Full term. The baby continues to build the fat that will help regulate their temperature.',
    motherExperience:
        'Contractions may start and stop. Real labour builds a regular, strengthening rhythm.',
  ),
  PregnancyWeek(
    week: 40,
    sizeComparison: 'a small pumpkin',
    emoji: '🎃',
    weightGrams: 3462,
    lengthCm: 51.2,
    babyDevelopment:
        'Your due date. Only about 1 in 20 babies actually arrive on it, so a little either way is normal.',
    motherExperience:
        'Waiting is the hardest part. Your midwife will discuss what happens if you go past 41 weeks.',
  ),
  PregnancyWeek(
    week: 41,
    sizeComparison: 'a pumpkin',
    emoji: '🎃',
    weightGrams: 3597,
    lengthCm: 51.5,
    babyDevelopment:
        'The baby is still growing and the placenta keeps working, though it is monitored more closely now.',
    motherExperience:
        'Extra monitoring is usual, and induction is often discussed around this point.',
  ),
  PregnancyWeek(
    week: 42,
    sizeComparison: 'a large pumpkin',
    emoji: '🎃',
    weightGrams: 3685,
    lengthCm: 51.7,
    babyDevelopment:
        'Skin may be dry or peeling because the vernix has gone. Nails may need cutting at birth.',
    motherExperience:
        'Post-term. Your team will be recommending a plan for delivery.',
  ),
];

/// The reference entry for a given week, clamped to the range covered.
PregnancyWeek pregnancyWeekInfo(int week) {
  final clamped = week.clamp(1, kPregnancyWeeks.length);
  return kPregnancyWeeks[clamped - 1];
}

/// How far through a 40-week pregnancy, 0..1.
double pregnancyProgress(int week) => (week / 40).clamp(0.0, 1.0).toDouble();

/// Days remaining to the due date, floored at zero.
int daysToGo(DateTime dueDate, {DateTime? from}) {
  final days = calendarDaysBetween(from ?? DateTime.now(), dueDate);
  return days < 0 ? 0 : days;
}
