/// Route paths, kept in one place so notification deep links and screens agree.
abstract final class AppRoutes {
  static const medicines = '/';
  static const addMedicine = '/medicines/new';
  static const newMedicineReminder = '/medicines/new/reminder';
  static String medicine(String id) => '/medicines/$id';
  static String newReminder(String medicineId) =>
      '/medicines/$medicineId/reminders/new';
  static String reminder(String id) => '/reminders/$id';
  static String editReminder(String id) => '/reminders/$id/edit';
}
