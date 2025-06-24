import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:project_travelplanner/graphql/query/getUser.dart';
import 'Page/editProfil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final void Function()? onProfileUpdated; // 👈 Tambahkan ini

  const ProfilePage({
    super.key,
    required this.userId,
    this.onProfileUpdated, // 👈 dan ini di konstruktor
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String phone = "";
  String email = "";
  String foto = "";
  String? password;
  bool isLoading = true;
  bool _isInit = true;

  late WebSocketChannel channel;

  String? _lastTripMessage;

  @override
  void initState() {
    super.initState();

    // Ganti IP ke '10.0.2.2' jika pakai emulator Android
    channel = IOWebSocketChannel.connect(
      'ws://10.0.2.2:4000?userId=${widget.userId}',
    );

    channel.stream.listen((message) {
      try {
        final decoded = jsonDecode(message);

        if (decoded['type'] == 'NOTIF') {
          final msg = decoded['message'];

          final String displayMessage =
              msg is String
                  ? msg
                  : 'Hai 👋 ${msg['nama']}, trip ke ${msg['location']} akan berangkat dalam 3 hari.';

          setState(() {
            _lastTripMessage = displayMessage;
          });

          showTripNotification(context, displayMessage);
        }
      } catch (e, stack) {
        print('❌ WebSocket error: $e');
        print(stack);
      }
    });
  }

  // 👇 Tambahkan di sini
  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      fetchUserData(widget.userId);
      _isInit = false;
    }
  }

  Future<void> fetchUserData(String userId) async {
    final client = GraphQLProvider.of(context).value;

    final result = await client.query(
      QueryOptions(
        document: gql(UserQueries.GetUser),
        variables: {'id': userId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      debugPrint("GraphQL Error: ${result.exception.toString()}");
      setState(() => isLoading = false);
    } else {
      final users = result.data?['users'];
      if (users != null && users.isNotEmpty) {
        final user = users[0];

        // Simpan nama ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', user['nama'] ?? "");

        setState(() {
          name = user['nama'] ?? "";
          phone = user['no_hp'] ?? "";
          email = user['email'] ?? "";
          password = user['password'];
          foto = user['foto'] ?? "";
          isLoading = false;
        });
      }
    }
  }

  void _openEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditProfilPage(
              userId: widget.userId,
              initialName: name,
              initialPhone: phone,
              initialEmail: email,
              initialFoto: foto,
              initialPassword: password,
              // kamu bisa tambahkan userId jika EditProfilPage butuh
            ),
      ),
    );

    if (result != null) {
      await fetchUserData(widget.userId);
      widget.onProfileUpdated?.call();
    }
  }

  void showTripNotification(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.only(bottom: 750, left: 10, right: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.cyan,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flight_takeoff, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 102, 141),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PhysicalShape(
                          clipper: SlightBottomCurveClipper(),
                          elevation: 20,
                          color: const Color.fromARGB(255, 210, 227, 238),
                          shadowColor: const Color(0x60000000),
                          child: SizedBox(
                            width: double.infinity,
                            height: 210,
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 33,
                                    left: 20,
                                    right: 1,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.notifications),
                                        onPressed: () {
                                          if (_lastTripMessage != null) {
                                            showTripNotification(
                                              context,
                                              _lastTripMessage!,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Belum ada notifikasi.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const Text(
                                        'Profil',
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            _openEditPage();
                                          } else if (value == 'logout') {
                                            final prefs =
                                                await SharedPreferences.getInstance();
                                            await prefs
                                                .clear(); // hapus semua data login

                                            // Navigasi balik ke halaman login/get started
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => const Login(),
                                              ),
                                              (route) =>
                                                  false, // hapus semua rute sebelumnya
                                            );
                                          }
                                        },

                                        itemBuilder:
                                            (BuildContext context) => [
                                              const PopupMenuItem<String>(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.edit_note,
                                                      size: 23,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text('Edit Profile'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuDivider(),
                                              const PopupMenuItem<String>(
                                                value: 'logout',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.logout,
                                                      color: Colors.red,
                                                      size: 23,
                                                    ),
                                                    SizedBox(width: 10),
                                                    Text(
                                                      'Logout',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 140,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ClipOval(
                              child: Container(
                                width: 140,
                                height: 140,
                                color: Colors.grey[200],
                                child:
                                    foto.isNotEmpty
                                        ? Image.memory(
                                          base64Decode(foto),
                                          fit: BoxFit.cover,
                                        )
                                        : Image.asset(
                                          'assets/images/profile.jpg',
                                          fit: BoxFit.cover,
                                        ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 120),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 34, 102, 141),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InfoRow(
                              icon: Icons.person,
                              label: 'Nama',
                              value: name,
                            ),
                            const Divider(thickness: 2),
                            InfoRow(
                              icon: Icons.phone,
                              label: 'No. HP',
                              value: phone,
                            ),
                            const Divider(thickness: 2),
                            InfoRow(
                              icon: Icons.email,
                              label: 'E-Mail',
                              value: email,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

class SlightBottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 16.5);
    final controlPoint = Offset(size.width / 2, size.height + 17);
    final endPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 26, color: Colors.white),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
