import 'package:flutter_test/flutter_test.dart';
import 'package:medkit/main.dart';

void main() {
  testWidgets('App launches', (tester) async {
    await tester.pumpWidget(const MedKitApp());
    await tester.pumpAndSettle();
    expect(find.byType(MedKitApp), findsOneWidget);
  });
}
