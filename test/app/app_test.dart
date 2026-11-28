import 'package:flutter_test/flutter_test.dart';
import 'package:sahaay/features/day/day_destinations.dart';

import '../support/test_app.dart';
import '../support/test_database.dart';

void main() {
  testWidgets('opens on Today', (tester) async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await pumpTestApp(tester, db: db, start: const TodayDestination());

    expect(find.text('good morning.'), findsOneWidget);
    expect(find.text('nothing for today.'), findsOneWidget);

    await disposeTestApp(tester);
  });
}
