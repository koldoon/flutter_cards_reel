import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cards_reel/sliver_cards_reel.dart';

import 'colorful_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            const SliverAppBar(),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 10,
                      right: 10,
                    ),
                    child: SizedBox(
                      height: 400,
                      child: ColorfulCard(index),
                    ),
                  );
                },
                childCount: 4,
              ),
            ),
            SliverCardsReel(
              itemExtent: 400,
              itemHeaderExtent: 100,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: SizedBox(
                      height: 400,
                      child: ColorfulCard(index),
                    ),
                  );
                },
                childCount: 4,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 10,
                      left: 10,
                      right: 10,
                    ),
                    child: SizedBox(
                      height: 400,
                      child: ColorfulCard(index),
                    ),
                  );
                },
                childCount: 4,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
