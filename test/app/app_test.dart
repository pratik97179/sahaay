import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/app/routes.dart';

import '../support/test_app.dart';
import '../support/test_database.dart';

void main() {
  testWidgets('opens on Today', (tester) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await pumpTestApp(tester, db: db, initialLocation: AppRoutes.today);

    expect(find.text('good morning.'), findsOneWidget);
    expect(find.text('nothing for today.'), findsOneWidget);

    await disposeTestApp(tester);
  });
}
