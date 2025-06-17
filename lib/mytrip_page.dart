import 'package:flutter/material.dart';
import 'package:project_travelplanner/graphql/query/myTrip.dart';
import 'trip_model.dart';
import 'package:intl/intl.dart';
import 'tour_detail_page.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MytripPage extends StatefulWidget {
  const MytripPage({super.key});

  @override
  State<MytripPage> createState() => _MytripPageState();
}

class _MytripPageState extends State<MytripPage> {
  List<Trip> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrips();
  }

  Future<void> fetchTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    final client = GraphQLProvider.of(context).value;

    final QueryResult result = await client.query(
      QueryOptions(
        document: gql(MyTripQueries.getTripsQuery),
        variables: {'userId': userId},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );

    if (!result.hasException) {
      final rawTrips = result.data?['trips'] ?? [];
      final List<Trip> parsedTrips =
          rawTrips.map<Trip>((json) => Trip.fromJson(json)).toList();

      setState(() {
        trips = parsedTrips;
        isLoading = false;
      });
    } else {
      print(result.exception.toString());
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDuration(Duration duration) {
    return '${duration.inDays}D : ${(duration.inHours % 24)}H : ${(duration.inMinutes % 60)}M';
  }

  String formatDateRange(DateTimeRange range) {
    final formatter = DateFormat('MMM d');
    return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
  }

  String formatNights(DateTimeRange range) {
    final days = range.duration.inDays;
    return '${days}N${days + 1}D';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F628E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F628E),
        elevation: 0,
        toolbarHeight: 80,
        title: const Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            'My Trip',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : trips.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.travel_explore, size: 60, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'No trips available.\nCreate your first trip now!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: trips.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final Trip trip = trips[index];
                  final dateRange = trip.dateRange;

                  final imageAsset =
                      'assets/images/${trip.location.trim().toUpperCase()}.jpg';

                  return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder:
                            (_) =>
                                TourDetailSheet(trip: trip, tripIndex: index),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      height: 138,
                      decoration: BoxDecoration(
                        color: const Color(0xFF86CBE9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            child: Image.asset(
                              imageAsset,
                              width: 138,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${formatDuration(dateRange.duration)} • ${formatNights(dateRange)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatDateRange(dateRange),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    trip.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          trip.location,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
