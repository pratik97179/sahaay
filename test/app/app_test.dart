import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';
import '../support/test_database.dart';

void main() {
  testWidgets('starts on the medicines page', (tester) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await pumpTestApp(tester, db: db);

    expect(find.text('Medicines'), findsOneWidget);
    expect(find.text('No medicines yet.'), findsOneWidget);

    await disposeTestApp(tester);
  });
}
