/// Asset paths for the Readme package.
///
/// Always pass [package] to [Image.asset] / [SvgPicture.asset] / [Lottie.asset]
/// so assets resolve when Readme is consumed as a dependency (not only as a
/// standalone app).
class AssetsPath {
  AssetsPath._();

  static const String package = 'Readme';

  static const String home = 'assets/images/home.svg';
  static const String search = 'assets/images/search.svg';
  static const String create = 'assets/images/create.svg';
  static const String trending = 'assets/images/trending.svg';
  static const String profile = 'assets/images/profile.svg';
  static const String googleIcon = 'assets/icons/Google.svg';
  static const String phoneIcon = 'assets/icons/phone.svg';
  static const String draftIcon = 'assets/icons/draft.svg';
  static const String exploreIcon = 'assets/icons/explore.svg';
  static const String communityIcon = 'assets/icons/community.svg';
  static const String homeNaveIcon = 'assets/icons/home.svg';
  static const String profileNaveIcon = 'assets/icons/profile.svg';
  static const String brandImage = 'assets/images/image 5.png';
  static const String emptyLottie = 'assets/lottie/empty.json';
}
