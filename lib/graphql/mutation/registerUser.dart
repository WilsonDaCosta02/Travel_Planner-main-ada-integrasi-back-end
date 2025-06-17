class RegisterUser {
  static const String createUserMutation = """
  mutation CreateUser(\$nama: String!, \$no_hp: String, \$email: String!, \$password: String!) {
    createUser(nama: \$nama, no_hp: \$no_hp, email: \$email, password: \$password) {
      id
      nama
      no_hp
      email
    }
  }
  """;
}
