class Deletetrip {
static String deleteTripMutation = r'''
mutation DeleteTrip($id: ID!) {
  deleteTrip(id: $id)
}
''';
}