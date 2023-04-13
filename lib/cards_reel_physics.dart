import 'package:flutter/material.dart';

class CardsReelPageScrollPhysics extends ScrollPhysics {
  const CardsReelPageScrollPhysics({
    required this.getPageIndexDelegate,
    required this.getScrollOffsetDelegate,
    this.maxScrollPagesAtOnce = 1,
    ScrollPhysics? parent,
  }) : super(parent: parent);

  final int maxScrollPagesAtOnce;
  final double Function(double scrollOffset) getPageIndexDelegate;
  final double Function(double page) getScrollOffsetDelegate;

  @override
  ScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CardsReelPageScrollPhysics(
      parent: buildParent(ancestor),
      getPageIndexDelegate: getPageIndexDelegate,
      getScrollOffsetDelegate: getScrollOffsetDelegate,
      maxScrollPagesAtOnce: maxScrollPagesAtOnce,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    // Create a test simulation to see where it would have ballistically fallen
    // naturally without settling onto items.
    final testFrictionSimulation = super.createBallisticSimulation(position, velocity);
    final suggestedSettlingPixels = testFrictionSimulation?.x(double.infinity) ?? position.pixels;

    final settlingPixels = _getSettlingPixels(
      position.pixels,
      suggestedSettlingPixels,
      tolerance,
      velocity,
    );

    if (settlingPixels != position.pixels)
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        settlingPixels,
        velocity,
        tolerance: tolerance,
      );

    return null;
  }

  double _getSettlingPixels(
    double currentPixels,
    double frictionSettlingPixels,
    Tolerance tolerance,
    double velocity,
  ) {
    var page = getPageIndexDelegate(currentPixels);
    final delta = (getPageIndexDelegate(frictionSettlingPixels - currentPixels))
        .abs()
        .clamp(0, maxScrollPagesAtOnce - 1);
    if (velocity < -tolerance.velocity) page -= 0.3 + delta;
    if (velocity > tolerance.velocity) page += 0.3 + delta;
    return getScrollOffsetDelegate(page.roundToDouble());
  }

  @override
  bool get allowImplicitScrolling => false;
}
