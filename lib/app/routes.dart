/// Route paths, kept in one place so notification deep links and screens agree.
abstract final class AppRoutes {
  static const medicines = '/';
  static const addMedicine = '/medicines/new';
  static String medicine(String id) => '/medicines/$id';
}
