import 'package:flutter/widgets.dart';

import 'cards_reel_physics.dart';
import 'sliver_cards_reel.dart';

class CardsReelView extends StatelessWidget {
  CardsReelView({
    required List<Widget> children,
    required this.itemExtent,
    required this.itemHeaderExtent,
    this.itemCount,
    this.maxScrollPagesAtOnce = 1,
    this.scrollToEnd = true,
    this.openFirstItem = true,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    super.key,
  }) {
    itemBuilder = (context, index) => children[index];
  }

  CardsReelView.builder({
    required NullableIndexedWidgetBuilder itemBuilder,
    required this.itemExtent,
    required this.itemHeaderExtent,
    this.itemCount,
    this.maxScrollPagesAtOnce = 1,
    this.scrollToEnd = true,
    this.openFirstItem = true,
    this.scrollDirection = Axis.vertical,
    this.controller,
    this.physics,
    super.key,
  }) {
    // ignore: prefer_initializing_formals
    this.itemBuilder = itemBuilder;
  }

  late final NullableIndexedWidgetBuilder itemBuilder;
  final double itemExtent;
  final double itemHeaderExtent;
  final ScrollController? controller;
  final int maxScrollPagesAtOnce;
  final ScrollPhysics? physics;
  final bool scrollToEnd;
  final bool openFirstItem;
  final Axis scrollDirection;
  final int? itemCount;

  double _getItemScrollOffset(double index) {
    return index * (itemExtent - itemHeaderExtent);
  }

  double _getItemIndex(double scrollOffset) {
    return scrollOffset / (itemExtent - itemHeaderExtent);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final ScrollContext scrollContext = Scrollable.of(notification.context!)!;
        scrollContext.setIgnorePointer(false);
        return false;
      },
      child: CustomScrollView(
        controller: controller,
        scrollDirection: scrollDirection,
        physics: physics ??
            CardsReelPageScrollPhysics(
              getPageIndexDelegate: _getItemIndex,
              getScrollOffsetDelegate: _getItemScrollOffset,
              maxScrollPagesAtOnce: maxScrollPagesAtOnce,
            ),
        slivers: [
          SliverCardsReel(
            itemExtent: itemExtent,
            itemHeaderExtent: itemHeaderExtent,
            scrollToEnd: scrollToEnd,
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
