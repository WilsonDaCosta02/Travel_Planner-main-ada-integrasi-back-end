import 'package:flutter/material.dart';

class Trip {
  final String id;
  final String title;
  final String location;
  final String remarks;
  final DateTimeRange dateRange;

  Trip({
    required this.id,
    required this.title,
    required this.location,
    required this.remarks,
    required this.dateRange,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['start_date']);
    final end = DateTime.parse(json['end_date']);

    return Trip(
      id: json['id'].toString(),
      title: json['title'],
      location: json['location'],
      remarks: json['remarks'],
      dateRange: DateTimeRange(start: start, end: end),
    );
  }
}
