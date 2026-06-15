// =============================================================================
// DATA MODEL
// =============================================================================

enum UserStatus { active, inactive, pending, suspended }

enum UserRole { admin, editor, viewer, guest }

class User {
  final String id;
  final String field1;
  final String field2;
  final String field3;
  final String field4;
  final int index;

  const User({
    required this.id,
    required this.field1,
    required this.field2,
    required this.field3,
    required this.field4,
    required this.index,
  });
}

List<User> generateUsers(int count) {
  return List.generate(count, (index) {
    return User(
      id: 'USR${(index + 1).toString().padLeft(5, '0')}',
      field1: 'field1（$index）',
      field2: 'field2（$index）',
      field3: 'field3（$index）',
      field4: 'field4（$index）',
      index: index,
    );
  });
}
