import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cards_reel/cards_reel_view.dart';

import 'colorful_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: CardsReelView.builder(
          itemExtent: 400,
          itemHeaderExtent: 100,
          maxScrollPagesAtOnce: 2,
          itemCount: 5,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 400,
                child: ColorfulCard(index),
              ),
            );
          },
        ),
      ),
    ),
  );
}
