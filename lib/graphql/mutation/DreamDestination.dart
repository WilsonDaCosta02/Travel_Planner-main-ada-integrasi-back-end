class DreamdestinationMutation {
  static const String createDreamDestination = r'''
  mutation CreateDreamDestination($user_id: ID!, $name: String!, $image: String!) {
    createDreamDestination(user_id: $user_id, name: $name, image: $image) {
      id
      user_id
      name
      image
    }
  }
''';

  static const String updateDreamDestination = r'''
  mutation UpdateDreamDestination($id: ID!, $name: String, $image: String) {
    updateDreamDestination(id: $id, name: $name, image: $image) {
      id
      user_id
      name
      image
    }
  }
''';

  static const String deleteDreamDestination = r'''
  mutation DeleteDreamDestination($id: ID!) {
    deleteDreamDestination(id: $id)
  }
''';
}
