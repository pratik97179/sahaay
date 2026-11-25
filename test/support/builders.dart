import 'package:sahaay/features/medicines/domain/medicine.dart';
import 'package:sahaay/features/reminders/domain/calendar.dart';
import 'package:sahaay/features/reminders/domain/recurrence.dart';
import 'package:sahaay/features/reminders/domain/reminder.dart';
import 'package:sahaay/features/reminders/domain/reminder_schedule.dart';

Medicine aMedicine({
  String id = 'm1',
  String? name = 'Paracetamol',
  MedicineForm form = MedicineForm.oral,
  String photo = 'm1.jpg',
}) => Medicine(id: id, name: name, form: form, photoPath: photo);

Reminder aReminder({
  String id = 'r1',
  String medicineId = 'm1',
  Recurrence? recurrence,
  LocalTime? time,
  LocalDate? start,
  LocalDate? end,
  String? quantity,
  String? instruction,
  bool paused = false,
}) => Reminder(
  id: id,
  medicineId: medicineId,
  schedule: ReminderSchedule(
    time: time ?? LocalTime(9, 0),
    recurrence: recurrence ?? DailyRecurrence(),
    startDate: start ?? LocalDate(2026, 11, 1),
    endDate: end,
  ),
  quantity: quantity,
  instruction: instruction,
  isPaused: paused,
);
