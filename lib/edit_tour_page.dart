import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:project_travelplanner/graphql/mutation/Trip.dart';
import 'package:table_calendar/table_calendar.dart';
import 'trip_model.dart';
import 'home.dart';
import 'dart:ui'; // For ImageFilter
import 'package:project_travelplanner/services/region_service.dart';

class EditTourPage extends StatefulWidget {
  final Trip trip;
  final int tripIndex;

  const EditTourPage({super.key, required this.trip, required this.tripIndex});

  @override
  State<EditTourPage> createState() => _EditTourPageState();
}

class _EditTourPageState extends State<EditTourPage> {
  late DateTime _rangeFocusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _tourAboutController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  List<String> _provinces = [];
  String? _selectedProvince;

  @override
  void initState() {
    super.initState();
    _loadProvinces();

    _rangeStart = widget.trip.dateRange.start;
    _rangeEnd = widget.trip.dateRange.end;
    _rangeFocusedDay = _rangeStart!;

    _tourAboutController.text = widget.trip.title;
    _locationController.text = widget.trip.location;
    _remarksController.text = widget.trip.remarks;
    _dateController.text =
        "${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year} - ${_rangeEnd!.day}/${_rangeEnd!.month}/${_rangeEnd!.year}";
  }

  void _loadProvinces() async {
    try {
      final data = await fetchProvinces(); // Sama seperti di AddTourPage
      setState(() {
        _provinces = data;
        if (_provinces.contains(widget.trip.location)) {
          _selectedProvince = widget.trip.location;
        }
      });
    } catch (e) {
      print('Gagal memuat data provinsi: $e');
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _tourAboutController.dispose();
    _locationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 102, 141),
      appBar: AppBar(
        title: const Text('Edit tour'),
        backgroundColor: const Color.fromARGB(255, 34, 102, 141),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCalendar(),
            const SizedBox(height: 20),
            _buildLabeledField('Date', null, _dateController),
            _buildLabeledField(
              "What's the tour about",
              null,
              _tourAboutController,
            ),
            _buildProvinceDropdown(),
            _buildLabeledField(
              'Remarks',
              null,
              _remarksController,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF89D2E4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _rangeFocusedDay = DateTime(
                        _rangeFocusedDay.year,
                        _rangeFocusedDay.month - 1,
                      );
                    });
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _rangeFocusedDay,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (picked != null) {
                      setState(() {
                        _rangeFocusedDay = picked;
                      });
                    }
                  },
                  child: Text(
                    "${DateFormat.MMMM().format(_rangeFocusedDay)} / ${_rangeFocusedDay.year}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _rangeFocusedDay = DateTime(
                        _rangeFocusedDay.year,
                        _rangeFocusedDay.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _rangeFocusedDay,
            calendarFormat: _calendarFormat,
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            rangeSelectionMode: _rangeSelectionMode,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                if (isSameDay(_rangeStart, selectedDay) && _rangeEnd == null) {
                  _rangeStart = null;
                  _rangeEnd = null;
                  _rangeSelectionMode = RangeSelectionMode.toggledOff;
                  _dateController.text = '';
                } else if (_rangeSelectionMode ==
                        RangeSelectionMode.toggledOn &&
                    _rangeStart != null &&
                    _rangeEnd == null &&
                    selectedDay.isAfter(_rangeStart!)) {
                  _rangeEnd = selectedDay;
                } else {
                  _rangeStart = selectedDay;
                  _rangeEnd = null;
                  _rangeSelectionMode = RangeSelectionMode.toggledOn;
                }

                _rangeFocusedDay = focusedDay;
                _dateController.text =
                    (_rangeStart != null && _rangeEnd != null)
                        ? "${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year} - ${_rangeEnd!.day}/${_rangeEnd!.month}/${_rangeEnd!.year}"
                        : (_rangeStart != null)
                        ? "${_rangeStart!.day}/${_rangeStart!.month}/${_rangeStart!.year}"
                        : "";
              });
            },
            onPageChanged: (focusedDay) {
              _rangeFocusedDay = focusedDay;
            },
            headerVisible: false,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
              ),
              weekendStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(color: Colors.black, fontSize: 16),
              weekendTextStyle: TextStyle(color: Colors.black, fontSize: 16),
              todayDecoration: BoxDecoration(
                color: Color.fromARGB(255, 34, 102, 141),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: Colors.white),
              selectedTextStyle: TextStyle(color: Colors.black),
              rangeHighlightColor: Color.fromARGB(132, 255, 255, 255),
              rangeStartTextStyle: TextStyle(color: Colors.black),
              rangeStartDecoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              rangeEndTextStyle: TextStyle(color: Colors.black),
              rangeEndDecoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedProvince,
        items:
            _provinces.map((prov) {
              return DropdownMenuItem(value: prov, child: Text(prov));
            }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedProvince = value;
            _locationController.text = value ?? '';
          });
        },
        decoration: InputDecoration(
          labelText: 'Location (Province)',
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 210, 210, 210),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFFFFADD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
        dropdownColor: const Color.fromARGB(255, 3, 49, 77),
        style: const TextStyle(color: Color(0xFFFFFADD)),
        iconEnabledColor: const Color(0xFFFFFADD),
      ),
    );
  }

  Widget _buildLabeledField(
    String label,
    IconData? icon,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        readOnly: label == 'Date',
        maxLines: maxLines,
        cursorColor: Colors.white,
        style: const TextStyle(color: Color(0xFFFFFADD)),
        decoration: InputDecoration(
          prefixIcon:
              icon != null ? Icon(icon, color: Color(0xFFFFFADD)) : null,
          labelText: label,
          labelStyle: const TextStyle(
            color: Color.fromARGB(255, 210, 210, 210),
            fontSize: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFFFFADD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFFFFADD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFC700),
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.update),
          label: const Text('Update'),
          onPressed: () async {
            if (_rangeStart != null && _rangeEnd != null) {
              final client = GraphQLProvider.of(context).value;

              final result = await client.mutate(
                MutationOptions(
                  document: gql(TripMutation.updateTripMutation),
                  variables: {
                    'id': widget.trip.id,
                    'title': _tourAboutController.text,
                    'location': _locationController.text,
                    'remarks': _remarksController.text,
                    'start_date': _rangeStart!.toIso8601String(),
                    'end_date': _rangeEnd!.toIso8601String(),
                  },
                ),
              );

              if (!result.hasException) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(initialTabIndex: 2),
                  ),
                  (route) => false,
                );
              } else {
                print(result.exception.toString());
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Update failed')));
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select a date range!')),
              );
            }
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          onPressed: () {
            _showDeleteConfirmationDialog();
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(
        0.4,
      ), // semi-transparent background
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // blur effect
          child: AlertDialog(
            backgroundColor: const Color(0xFFFFFADD), // cream color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Are you sure?',
              style: TextStyle(color: Colors.black),
            ),
            content: const Text(
              'Do you want to delete the tour details?',
              style: TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: const Text('No', style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () async {
                  final client = GraphQLProvider.of(context).value;

                  final result = await client.mutate(
                    MutationOptions(
                      document: gql(TripMutation.deleteTripMutation),
                      variables: {'id': widget.trip.id},
                    ),
                  );

                  if (!result.hasException &&
                      result.data?['deleteTrip'] == true) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => HomePage(initialTabIndex: 2),
                      ),
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pop(); // Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delete failed')),
                    );
                  }
                },
                child: const Text('Yes', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }
}
