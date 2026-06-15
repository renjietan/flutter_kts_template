// =============================================================================
// DATA MODEL
// =============================================================================

enum UserStatus { active, inactive, pending, suspended }

enum UserRole { admin, editor, viewer, guest }

class User {
  final String id;
  final String name;
  final String email;
  final String department;
  final UserRole role;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime lastLogin;
  final int loginCount;
  final double score;
  final int index;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.lastLogin,
    required this.loginCount,
    required this.score,
    required this.index
  });

  String get formattedCreatedAt =>
      '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';

  String get formattedLastLogin =>
      '${lastLogin.year}-${lastLogin.month.toString().padLeft(2, '0')}-${lastLogin.day.toString().padLeft(2, '0')} '
          '${lastLogin.hour.toString().padLeft(2, '0')}:${lastLogin.minute.toString().padLeft(2, '0')}';

  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.editor:
        return 'Editor';
      case UserRole.viewer:
        return 'Viewer';
      case UserRole.guest:
        return 'Guest';
    }
  }

  String get statusLabel {
    switch (status) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.inactive:
        return 'Inactive';
      case UserStatus.pending:
        return 'Pending';
      case UserStatus.suspended:
        return 'Suspended';
    }
  }
}

List<User> generateUsers(int count) {
  final firstNames = [
    'James', 'Mary', 'John', 'Patricia', 'Robert', 'Jennifer', 'Michael',
    'Linda', 'William', 'Elizabeth', 'David', 'Barbara', 'Richard', 'Susan',
    'Joseph', 'Jessica', 'Thomas', 'Sarah', 'Charles', 'Karen', 'Wei', 'Fang',
    'Ming', 'Li', 'Chen', 'Wang', 'Zhang', 'Liu', 'Yang', 'Huang',
  ];

  final lastNames = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
    'Davis', 'Rodriguez', 'Martinez', 'Anderson', 'Taylor', 'Thomas', 'Moore',
    'Jackson', 'Martin', 'Lee', 'Thompson', 'White', 'Harris', 'Chen', 'Wang',
    'Li', 'Zhang', 'Liu', 'Yang', 'Huang', 'Wu', 'Zhou', 'Xu',
  ];

  final departments = [
    'Engineering', 'Marketing', 'Sales', 'Finance', 'HR', 'Operations',
    'Product', 'Design', 'Legal', 'Support', 'Research', 'IT',
  ];

  final baseDate = DateTime(2024, 1, 1);

  return List.generate(count, (index) {
    final firstName = firstNames[index % firstNames.length];
    final lastName = lastNames[(index * 7) % lastNames.length];
    final name = '$firstName $lastName';
    final email =
        '${firstName.toLowerCase()}.${lastName.toLowerCase()}$index@example.com';

    return User(
        id: 'USR${(index + 1).toString().padLeft(5, '0')}',
        name: name,
        email: email,
        department: departments[index % departments.length],
        role: UserRole.values[index % UserRole.values.length],
        status: UserStatus.values[index % UserStatus.values.length],
        createdAt: baseDate.subtract(Duration(days: index * 3)),
        lastLogin: baseDate.subtract(
          Duration(hours: index * 5, minutes: index * 17),
        ),
        loginCount: (index * 13 + 5) % 500,
        score: ((index * 17 + 30) % 100) + (index % 10) / 10,
        index: index
    );
  });
}