/// Route paths, kept in one place so notification deep links and screens agree.
abstract final class AppRoutes {
  /// Today, the home screen.
  static const today = '/';
  static const medicines = '/medicines';
  static const addMedicine = '/medicines/new';
  static String medicine(String id) => '/medicines/$id';
  static String newReminder(String medicineId) =>
      '/medicines/$medicineId/reminders/new';
  static String reminder(String id) => '/reminders/$id';
}
