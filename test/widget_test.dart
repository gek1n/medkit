import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medkit/main.dart';

void main() {
  testWidgets('App launches', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MedKitApp()),
    );
    await tester.pump();
    expect(find.byType(MedKitApp), findsOneWidget);
  });
}
