import 'bootstrap.dart';
import 'core/brand/brands.dart';

/// Default entry point — **Apex Deals**.
///
/// A bare `flutter run` or `flutter build` lands here, which is why Apex Deals is
/// the default brand. ToolsHub builds pass `-t lib/main_toolshub.dart`.
///
/// Android additionally needs `--flavor apexdeals` to get the right app name and
/// bundle id. Web has no `--flavor` support at all (Flutter's build_web command
/// ignores it), so on web the entry point is the only brand selector.
void main() => bootstrap(kApexDeals);
