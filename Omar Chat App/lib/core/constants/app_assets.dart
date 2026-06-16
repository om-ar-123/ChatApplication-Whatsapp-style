/// Bundled asset paths used for default profile photo and photo status.
class AppAssets {
  AppAssets._();

  static const mountainLandscape = 'assets/images/mountain_landscape.png';

  /// Prefix stored in DB for asset-backed images (profile, status, etc.).
  static const assetPrefix = 'asset:';

  static String assetPath(String asset) => '$assetPrefix$asset';
}
