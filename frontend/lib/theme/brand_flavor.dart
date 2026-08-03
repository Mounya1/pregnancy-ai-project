import '../models/user_profile.dart';
import 'app_theme.dart';

/// Decides which brand colour the app wears for a given profile.
///
/// Violet throughout the pregnancy, then the baby's colour once they arrive:
/// blossom for a girl, sky for a boy. Gender is optional and often not known,
/// so anything unstated stays violet rather than guessing - the app should
/// never pick a colour that implies something the user did not tell it.
BrandFlavor flavorForProfile(UserProfile profile) {
  if (profile.lifeStage == LifeStage.pregnancy) return BrandFlavor.violet;

  switch (profile.babyGender) {
    case BabyGender.girl:
      return BrandFlavor.blossom;
    case BabyGender.boy:
      return BrandFlavor.sky;
    case BabyGender.unspecified:
      return BrandFlavor.violet;
  }
}

/// Whether the profile is at a point where the baby's colour applies, used to
/// decide if the gender picker is worth showing.
bool usesBabyFlavor(UserProfile profile) =>
    profile.lifeStage == LifeStage.breastfeeding ||
    profile.lifeStage == LifeStage.postpartum;
