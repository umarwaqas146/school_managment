import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sapient_school/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SapientSchoolApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('The Sapient School'), findsOneWidget);
  });
}
