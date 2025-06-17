class EditprofilMutation {
  static String mutation = r'''
    mutation UpdateUser($id: ID!, $nama: String, $no_hp: String, $email: String, $password: String, $foto: String) {
      updateUser(
        id: $id,
        nama: $nama,
        no_hp: $no_hp,
        email: $email,
        password: $password,
        foto: $foto
      ) {
        id
        nama
        no_hp
        email
        foto
      }
    }
  ''';
}
