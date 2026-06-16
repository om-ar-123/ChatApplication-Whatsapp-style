import 'package:intl/intl.dart';
import '../constants/db_constants.dart';

class DateTimeUtils {
  DateTimeUtils._();

  static String nowIso() => DateTime.now().toUtc().toIso8601String();

  static DateTime? parseIso(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static bool isWithinMinutes(String? createdAt, int minutes) {
    final created = parseIso(createdAt);
    if (created == null) return false;
    return DateTime.now().toUtc().difference(created.toUtc()).inMinutes <= minutes;
  }

  static bool canEditMessage(String? createdAt) =>
      isWithinMinutes(createdAt, DbConstants.editWindowMinutes);

  static bool canDeleteForAll(String? createdAt) =>
      isWithinMinutes(createdAt, DbConstants.deleteForAllWindowMinutes);

  static String formatChatTime(String? iso) {
    final date = parseIso(iso);
    if (date == null) return '';
    final local = date.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return DateFormat('HH:mm').format(local);
    }
    if (now.difference(local).inDays < 7) {
      return DateFormat('EEE').format(local);
    }
    return DateFormat('dd/MM/yy').format(local);
  }

  static String formatMessageTime(String? iso) {
    final date = parseIso(iso);
    if (date == null) return '';
    return DateFormat('HH:mm').format(date.toLocal());
  }
}
