class TripMutation {
  static const String createTripMutation = """
    mutation CreateTrip(
      \$user_id: ID!,
      \$title: String!,
      \$location: String!,
      \$remarks: String,
      \$start_date: String!,
      \$end_date: String!
    ) {
      createTrip(
        user_id: \$user_id,
        title: \$title,
        location: \$location,
        remarks: \$remarks,
        start_date: \$start_date,
        end_date: \$end_date
      ) {
        id
        title
        location
      }
    }
  """;

  static const String updateTripMutation = r"""
    mutation UpdateTrip(
      $id: ID!
      $title: String
      $location: String
      $remarks: String
      $start_date: String
      $end_date: String
    ) {
      updateTrip(
        id: $id
        title: $title
        location: $location
        remarks: $remarks
        start_date: $start_date
        end_date: $end_date
      ) {
        id
        title
        location
        start_date
        end_date
      }
    }
  """;

  static String deleteTripMutation = r"""
    mutation DeleteTrip($id: ID!) {
      deleteTrip(id: $id)
    }
  """;
}
