class NlpDateParser {
  static DateTime parseNaturalLanguage(String text) {
    final lower = text.toLowerCase().trim();
    final now = DateTime.now();

    if (lower.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1, 9, 0);
    } else if (lower.contains('tonight')) {
      return DateTime(now.year, now.month, now.day, 20, 0);
    } else if (lower.contains('next friday')) {
      int daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
      if (daysUntilFriday == 0) daysUntilFriday = 7;
      return DateTime(now.year, now.month, now.day + daysUntilFriday, 10, 0);
    } else if (lower.contains('next monday')) {
      int daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
      if (daysUntilMonday == 0) daysUntilMonday = 7;
      return DateTime(now.year, now.month, now.day + daysUntilMonday, 10, 0);
    }

    return now.add(const Duration(hours: 2));
  }

  static String formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $period';
  }
}
