import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hero banner renders branding copy', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeroBanner(
            title: 'CareerAI Coach',
            subtitle: 'Personalized career growth, fully offline.',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CareerAI Coach'), findsOneWidget);
    expect(
      find.text('Personalized career growth, fully offline.'),
      findsOneWidget,
    );
  });
}
