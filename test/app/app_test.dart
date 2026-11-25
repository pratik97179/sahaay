import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/app/app.dart';

void main() {
  testWidgets('starts on the medicines page', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SahaayApp()));
    await tester.pumpAndSettle();

    expect(find.text('Medicines'), findsOneWidget);
    expect(find.text('No medicines yet.'), findsOneWidget);
  });
}
