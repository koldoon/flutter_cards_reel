import 'package:flutter/widgets.dart';
import 'package:flutter_cards_reel/sliver_cards_reel.dart';

import 'cards_reel_physics.dart';

class CardsReelView extends StatelessWidget {
  CardsReelView({
    required List<Widget> children,
    required this.itemExtent,
    required this.itemHeaderExtent,
    this.itemCount,
    this.maxScrollPagesAtOnce = 1,
    this.standAloneSliver = true,
    this.openFirstItem = true,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    super.key,
  }) : itemBuilder = makeBuilder(children);

  const CardsReelView.builder({
    required this.itemExtent,
    required this.itemHeaderExtent,
    required this.itemBuilder,
    this.itemCount,
    this.maxScrollPagesAtOnce = 1,
    this.standAloneSliver = true,
    this.openFirstItem = true,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    super.key,
  });

  static NullableIndexedWidgetBuilder makeBuilder(List<Widget> children) {
    return (context, index) {
      if (index >= children.length) {
        return null;
      }
      return children[index];
    };
  }

  final NullableIndexedWidgetBuilder itemBuilder;
  final double itemExtent;
  final double itemHeaderExtent;
  final ScrollController? controller;
  final int maxScrollPagesAtOnce;
  final ScrollPhysics? physics;
  final bool standAloneSliver;
  final bool openFirstItem;
  final Axis scrollDirection;
  final int? itemCount;

  double getItemScrollOffset(double index) {
    return index * (itemExtent - itemHeaderExtent);
  }

  double getItemIndex(double scrollOffset) {
    return scrollOffset / (itemExtent - itemHeaderExtent);
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT ABOUT PHYSICS:
    // So far it is impossible to change physics and related properties reactively.
    // @see: https://github.com/flutter/flutter/issues/80051
    final physics = this.physics ??
        CardsReelPageScrollPhysics(
          getPageIndexDelegate: getItemIndex,
          getScrollOffsetDelegate: getItemScrollOffset,
          maxScrollPagesAtOnce: maxScrollPagesAtOnce,
        );

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final ScrollContext scrollContext = Scrollable.of(notification.context!);
        // This is needed to allow children selection while animation is playing
        scrollContext.setIgnorePointer(false);
        return false;
      },
      child: CustomScrollView(
        controller: controller,
        scrollDirection: scrollDirection,
        physics: physics,
        slivers: [
          SliverCardsReel(
            itemExtent: itemExtent,
            itemHeaderExtent: itemHeaderExtent,
            scrollToEnd: standAloneSliver,
            openFirstItem: openFirstItem,
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
            ),
          ),
        ],
      ),
    );
  }
}
