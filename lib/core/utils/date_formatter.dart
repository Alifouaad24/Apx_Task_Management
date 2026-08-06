import 'package:intl/intl.dart';

/// Date/time formatting helpers shared by task cards, details and comments.
class DateFormatter {
  const DateFormatter._();

  static final DateFormat _dayMonth = DateFormat('d MMM');
  static final DateFormat _dayMonthYear = DateFormat('d MMM yyyy');
  static final DateFormat _full = DateFormat('d MMM yyyy • HH:mm');
  static final DateFormat _timeOnly = DateFormat('HH:mm');

  /// `12 Mar 2026` — drops the year when the date is in the current year.
  static String short(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    return local.year == DateTime.now().year
        ? _dayMonth.format(local)
        : _dayMonthYear.format(local);
  }

  /// `12 Mar 2026` — always includes the year.
  static String medium(DateTime? date) =>
      date == null ? '—' : _dayMonthYear.format(date.toLocal());

  /// `12 Mar 2026 • 14:03`.
  static String full(DateTime? date) =>
      date == null ? '—' : _full.format(date.toLocal());

  static String time(DateTime? date) =>
      date == null ? '—' : _timeOnly.format(date.toLocal());

  /// Human relative label: `just now`, `5m ago`, `3h ago`, `Yesterday`,
  /// `4d ago`, then falls back to an absolute date.
  static String relative(DateTime? date) {
    if (date == null) return '—';
    final local = date.toLocal();
    final diff = DateTime.now().difference(local);

    if (diff.isNegative) {
      // Future date (e.g. a due date) — describe the remaining time instead.
      final ahead = local.difference(DateTime.now());
      if (ahead.inMinutes < 60) return 'in ${ahead.inMinutes}m';
      if (ahead.inHours < 24) return 'in ${ahead.inHours}h';
      if (ahead.inDays < 7) return 'in ${ahead.inDays}d';
      return short(local);
    }

    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return short(local);
  }

  /// Groups timeline entries under `Today` / `Yesterday` / a date header.
  static String dayHeader(DateTime date) {
    final local = DateTime(date.toLocal().year, date.toLocal().month, date.toLocal().day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delta = today.difference(local).inDays;

    if (delta == 0) return 'Today';
    if (delta == 1) return 'Yesterday';
    return medium(local);
  }

  /// `true` when a due date has passed.
  static bool isOverdue(DateTime? due) =>
      due != null && due.toLocal().isBefore(DateTime.now());

  /// Whole days remaining until [due]; negative once overdue.
  static int? daysUntil(DateTime? due) {
    if (due == null) return null;
    final now = DateTime.now();
    final target = due.toLocal();
    return DateTime(target.year, target.month, target.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }
}
