class MyTripQueries {
  static const String getTripsQuery = """
    query TripsByUser(\$userId: ID!) {
      trips(user_id: \$userId) {
        id
        title
        location
        remarks
        start_date
        end_date
      }
    }
  """;
}