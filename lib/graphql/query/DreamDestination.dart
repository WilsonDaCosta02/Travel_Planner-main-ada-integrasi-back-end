class DreamDestinationQueries {
  static const String getDreamDestinations = r'''
  query GetDreamDestinations($user_id: ID!) {
    dreamDestinations(user_id: $user_id) {
      id
      user_id
      name
      image
    }
  }
''';
}
