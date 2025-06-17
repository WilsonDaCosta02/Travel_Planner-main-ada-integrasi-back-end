class UserQueries {
  static const String GetUser = r'''
    query GetUser($id: ID!) {
      users(id: $id) {
        id
        nama
        no_hp
        email
        password
        foto
      }
    }
  ''';
}
