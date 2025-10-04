/// DemoDataPopulator - Handles populating demo data for testing
/// Follows Single Responsibility Principle: Only handles demo data operations
class DemoDataPopulator {
  /// Populates demo data for all form fields
  static Map<String, dynamic> getDemoData() {
    return {
      'name': 'राहुल पाटील',
      'age': 42,
      'gender': 'पुरुष',
      'education': 'B.A. Political Science',
      'profession': 'Businessman',
      'languages': ['Marathi', 'Hindi', 'English'],
      'experienceYears': 15,
      'previousPositions': ['Ward Councilor', 'Social Worker'],
      'symbolName': 'Lotus',
      'address': 'पुणे, महाराष्ट्र',
      'date_of_birth': '1982-01-15T00:00:00.000Z',
    };
  }
}