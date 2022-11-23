import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliverCardsReel extends SliverMultiBoxAdaptorWidget {
  const SliverCardsReel({
    required super.delegate,
    required this.itemHeaderExtent,
    required this.itemExtent,
    this.scrollToEnd = false,
    this.openFirstItem = true,
    super.key,
  });

  final bool openFirstItem;
  final bool scrollToEnd;
  final double itemExtent;
  final double itemHeaderExtent;

  @override
  SliverMultiBoxAdaptorElement createElement() {
    return SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);
  }

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverCardsReel(
      childManager: element,
      itemExtent: itemExtent,
      itemHeaderExtent: itemHeaderExtent,
      scrollToEnd: scrollToEnd,
      openFirstItem: openFirstItem,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverCardsReel renderObject) {
    renderObject
      ..itemExtent = itemExtent
      ..itemHeaderExtent = itemHeaderExtent
      ..scrollToEnd = scrollToEnd
      ..openFirstItem = openFirstItem;
  }
}

class RenderSliverCardsReel extends RenderSliverMultiBoxAdaptor {
  RenderSliverCardsReel({
    required RenderSliverBoxChildManager childManager,
    required this.itemHeaderExtent,
    required this.itemExtent,
    this.scrollToEnd = false,
    this.openFirstItem = true,
  }) : super(childManager: childManager);

  /// It is possible tp restrict first item to be opened in some special cases
  bool openFirstItem;

  /// If there are several slivers in single [CustomScrollView] and this sliver
  /// is in the middle, this property must be false. Otherwise when the last card
  /// is scrolled to upper position user will have to do some extra scrolling
  /// to get next sliver scrolled (looks like CustomScrollView bug)
  bool scrollToEnd;
  double itemExtent;
  double itemHeaderExtent;

  @override
  void performLayout() {
    final constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    final scrollUnit = itemExtent - itemHeaderExtent;
    final firstVisibleIndex = (constraints.scrollOffset / scrollUnit - 1).floor();
    // There is almost no point to have less than 2 visible items
    var visibleItemsCount = max(2, ((constraints.viewportMainAxisExtent - itemExtent) / itemHeaderExtent + 1).ceil());
    if (!openFirstItem) {
      visibleItemsCount += 1;
    }
    final lastVisibleIndex = firstVisibleIndex + visibleItemsCount;
    final childConstraints = constraints.asBoxConstraints();

    // Make sure we have at least one child to start from.
    if (firstChild == null) {
      if (!addInitialChild()) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
    }

    // Ensure we have all visible children needed
    while (indexOf(firstChild!) > firstVisibleIndex) {
      final child = insertAndLayoutLeadingChild(childConstraints, parentUsesSize: true);
      if (child == null) break;
    }

    var reachedEnd = false;
    while (indexOf(lastChild!) < lastVisibleIndex) {
      final child = insertAndLayoutChild(childConstraints, after: lastChild, parentUsesSize: true);
      if (child == null) {
        reachedEnd = true;
        break;
      }
    }

    // Select layout strategy
    final lastScrollableItemIndex = openFirstItem ? indexOf(lastChild!) : max(0, indexOf(lastChild!) - 1);
    final isRollingIn = openFirstItem && constraints.scrollOffset < itemExtent - itemHeaderExtent;
    final isRollingOut = reachedEnd && constraints.scrollOffset > lastScrollableItemIndex * scrollUnit;

    CardsReelLayout layout;
    if (isRollingIn) {
      layout = CardsReelRollingInLayout(
        itemExtent: itemExtent,
        itemHeaderExtent: itemHeaderExtent,
        scrollOffset: constraints.scrollOffset,
      );
    } else if (isRollingOut) {
      layout = CardsReelRollingOutLayout(
        itemExtent: itemExtent,
        itemHeaderExtent: itemHeaderExtent,
        scrollOffset: constraints.scrollOffset,
        lastItemIndex: indexOf(lastChild!),
        openFirstItem: openFirstItem,
      );
    } else {
      layout = CardsReelIntermediateLayout(
        itemExtent: itemExtent,
        itemHeaderExtent: itemHeaderExtent,
        scrollOffset: constraints.scrollOffset,
        visibleItemsCount: visibleItemsCount,
        openFirstItem: openFirstItem,
      );
    }

    // Perform layout for visible items, collect and remove invisible ones except the last one:
    // it is required for correct layout of the next sliver if present
    var leadingGarbage = 0;
    var trailingGarbage = 0;
    visitChildren((child) {
      final childParentData = child.parentData as SliverMultiBoxAdaptorParentData;
      final childIndex = indexOf(child as RenderBox);

      if (childIndex < firstVisibleIndex && childIndex != childManager.childCount - 1) {
        leadingGarbage++;
      } else if (childIndex > lastVisibleIndex) {
        trailingGarbage++;
      } else {
        child.layout(childConstraints, parentUsesSize: true);
        childParentData.layoutOffset = layout.getItemPosition(itemIndex: childIndex) + constraints.overlap;
      }
    });
    collectGarbage(leadingGarbage, trailingGarbage);

    var scrollExtent = double.infinity;
    var paintExtent = constraints.remainingPaintExtent;

    if (reachedEnd) {
      final lastChildParentData = lastChild!.parentData as SliverMultiBoxAdaptorParentData;
      paintExtent = lastChildParentData.layoutOffset! - constraints.scrollOffset + paintExtentOf(lastChild!);

      if (scrollToEnd) {
        scrollExtent = (childManager.childCount - 1) * scrollUnit + constraints.remainingPaintExtent;
      } else {
        scrollExtent = lastChildParentData.layoutOffset! + paintExtentOf(lastChild!);
      }
    }

    var paintOrigin = constraints.overlap < 0.0 ? -constraints.overlap : 0.0;
    paintExtent = (paintExtent - paintOrigin - precisionErrorTolerance);
    if (paintExtent < 0) paintExtent = 0;
    if (paintExtent + paintOrigin > constraints.remainingPaintExtent) paintExtent = constraints.remainingPaintExtent - paintOrigin;

    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintOrigin: paintOrigin,
      paintExtent: paintExtent,
      maxPaintExtent: paintExtent,
      hasVisualOverflow: true,
    );

    childManager.didFinishLayout();
  }
}

abstract class CardsReelLayout {
  double getItemPosition({required int itemIndex});
}

class CardsReelRollingInLayout implements CardsReelLayout {
  CardsReelRollingInLayout({
    required this.itemExtent,
    required this.itemHeaderExtent,
    required this.scrollOffset,
  });

  final double itemExtent;
  final double itemHeaderExtent;
  final double scrollOffset;

  @override
  double getItemPosition({required int itemIndex}) {
    assert(
      scrollOffset - precisionErrorTolerance <= itemExtent - itemHeaderExtent,
      'This layout works only for scroll offsets < (itemExtent - itemsOverlapExtent)',
    );
    if (itemIndex == 0) {
      return scrollOffset;
    } else if (itemIndex == 1) {
      return scrollOffset + itemExtent - scrollOffset;
    } else {
      return scrollOffset + itemExtent + itemHeaderExtent * (itemIndex - 1);
    }
  }
}

class CardsReelRollingOutLayout implements CardsReelLayout {
  CardsReelRollingOutLayout({
    required this.itemExtent,
    required this.itemHeaderExtent,
    required this.scrollOffset,
    required this.lastItemIndex,
    required this.openFirstItem,
  });

  final bool openFirstItem;
  final double itemExtent;
  final double itemHeaderExtent;
  final double scrollOffset;
  final int lastItemIndex;

  @override
  double getItemPosition({required int itemIndex}) {
    final scrollUnit = itemExtent - itemHeaderExtent;
    double lastScrollableItemPosition;
    if (openFirstItem) {
      lastScrollableItemPosition = itemHeaderExtent + scrollUnit * lastItemIndex;
    } else {
      lastScrollableItemPosition = itemHeaderExtent + scrollUnit * (lastItemIndex - 1);
    }
    if (itemIndex != lastItemIndex && scrollOffset < lastScrollableItemPosition) {
      return scrollOffset;
    } else {
      return lastScrollableItemPosition;
    }
  }
}

class CardsReelIntermediateLayout implements CardsReelLayout {
  CardsReelIntermediateLayout({
    required this.itemExtent,
    required this.itemHeaderExtent,
    required this.scrollOffset,
    required this.visibleItemsCount,
    required this.openFirstItem,
  }) {
    _virtualViewportExtent = (itemExtent - itemHeaderExtent) * visibleItemsCount;
    _tween = _buildLayoutTween();
  }

  final double scrollOffset;
  final double itemExtent;
  final double itemHeaderExtent;
  final int visibleItemsCount;
  final bool openFirstItem;

  late double _virtualViewportExtent;
  late TweenSequence<double> _tween;

  @override
  double getItemPosition({required int itemIndex}) {
    final scrollUnit = itemExtent - itemHeaderExtent;
    double itemAbsolutePosition;
    if (openFirstItem) {
      itemAbsolutePosition = (itemIndex + 1) * scrollUnit;
    } else {
      itemAbsolutePosition = itemIndex * scrollUnit;
    }
    final itemViewportPosition = itemAbsolutePosition - scrollOffset;
    final childRelativePosition = (itemViewportPosition / _virtualViewportExtent).clamp(0.0, 1.0);
    return scrollOffset + _tween.transform(childRelativePosition);
  }

  /// Build a tween that transform child position on virtual scroll viewport into
  /// real screen vertical position
  TweenSequence<double> _buildLayoutTween() {
    final tweenItems = <TweenSequenceItem<double>>[];
    var extent = 0.0;
    for (var i = 0; i < visibleItemsCount; i++) {
      if (i == 1) {
        // Second (visible on the screen) card must be fully open
        tweenItems.add(TweenSequenceItem(tween: Tween(begin: extent, end: extent + itemExtent), weight: 1));
        extent += itemExtent;
      } else {
        tweenItems.add(TweenSequenceItem(tween: Tween(begin: extent, end: extent + itemHeaderExtent), weight: 1));
        extent += itemHeaderExtent;
      }
    }
    return TweenSequence(tweenItems);
  }
}
