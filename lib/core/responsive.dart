import 'package:flutter/widgets.dart';

/// Layout breakpoints for the responsive web/mobile storefront.
class Breakpoints {
  Breakpoints._();

  static const double mobile = 640;
  static const double tablet = 1024;
  static const double maxContentWidth = 1240;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < Breakpoints.mobile;
  bool get isTablet =>
      screenWidth >= Breakpoints.mobile && screenWidth < Breakpoints.tablet;
  bool get isDesktop => screenWidth >= Breakpoints.tablet;

  /// Number of columns for the product grid at the current width.
  int get productGridColumns => isDesktop ? 4 : (isTablet ? 3 : 2);
}

/// Centers content and caps it at [maxWidth] on wide (web) screens, with
/// responsive horizontal padding. Used to give the storefront the Shopcart-style
/// centered desktop layout while staying edge-to-edge on phones.
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double? horizontalPadding;
  final double verticalPadding;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.horizontalPadding,
    this.verticalPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = horizontalPadding ?? (context.isMobile ? 16.0 : 24.0);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
