/// Utility class for formatting time strings for comments and posts
class TimeFormatterUtil {
  TimeFormatterUtil._();

  /// Format comment/post time into human-readable format
  /// 
  /// Examples:
  /// - "2d ago" for days
  /// - "5h ago" for hours  
  /// - "30m ago" for minutes
  /// - "Just now" for seconds
  static String formatCommentTime(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  /// Format date for media posts (e.g., "2023-12-25" -> "Dec 25, 2023")
  static String formatMediaDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  /// Check if a date is from today
  static bool isToday(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return date.year == now.year && 
             date.month == now.month && 
             date.day == now.day;
    } catch (e) {
      return false;
    }
  }
}
