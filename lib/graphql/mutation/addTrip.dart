class AddTripMutation {
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
}
