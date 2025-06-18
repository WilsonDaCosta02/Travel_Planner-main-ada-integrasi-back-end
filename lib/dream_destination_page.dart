import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'dart:convert'; // untuk base64
import 'package:project_travelplanner/graphql/mutation/DreamDestination.dart';
import 'package:project_travelplanner/graphql/query/DreamDestination.dart';

class DreamDestination {
  final int id;
  final String userId;
  final String name;
  final String imageBase64;

  DreamDestination({
    required this.id,
    required this.userId,
    required this.name,
    required this.imageBase64,
  });

  factory DreamDestination.fromJson(Map<String, dynamic> json) {
    return DreamDestination(
      id: int.parse(json['id'].toString()),
      userId: json['user_id'].toString(),
      name: json['name'],
      imageBase64: json['image'],
    );
  }
}

class DreamDestinationPage extends StatefulWidget {
  final String userId;
  const DreamDestinationPage({super.key, required this.userId});

  @override
  _DreamDestinationPageState createState() => _DreamDestinationPageState();
}

class _DreamDestinationPageState extends State<DreamDestinationPage> {
  List<Map<String, String>> destinations = [];

  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      loadDestinations();
      _hasLoaded = true;
    }
  }

  Future<void> addDreamDestination(String name, File imageFile) async {
    final client = GraphQLProvider.of(context).value;

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final result = await client.mutate(
      MutationOptions(
        document: gql(DreamdestinationMutation.createDreamDestination),
        variables: {
          'user_id': widget.userId,
          'name': name,
          'image': base64Image,
        },
      ),
    );

    if (result.hasException) {
      print(result.exception.toString());
    } else {
      print("Sukses menambahkan destinasi impian!");
      loadDestinations(); // refresh list
    }
  }

  Future<void> editDreamDestination({
    required int id,
    required String name,
    File? newImageFile,
    String? existingBase64Image,
  }) async {
    final client = GraphQLProvider.of(context).value;

    String base64Image = existingBase64Image ?? "";
    if (newImageFile != null) {
      final bytes = await newImageFile.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final result = await client.mutate(
      MutationOptions(
        document: gql(DreamdestinationMutation.updateDreamDestination),
        variables: {'id': id, 'name': name, 'image': base64Image},
      ),
    );

    if (result.hasException) {
      print(result.exception.toString());
    } else {
      print("Sukses mengedit destinasi!");
      await loadDestinations();
    }
  }

  Future<void> deleteDreamDestination(int id) async {
    final client = GraphQLProvider.of(context).value;

    final result = await client.mutate(
      MutationOptions(
        document: gql(DreamdestinationMutation.deleteDreamDestination),
        variables: {'id': id},
      ),
    );

    if (result.hasException) {
      print(result.exception.toString());
    } else {
      print("Sukses menghapus destinasi!");
      await loadDestinations();
    }
  }

  Future<void> loadDestinations() async {
    final client = GraphQLProvider.of(context).value;

    final result = await client.query(
      QueryOptions(
        document: gql(DreamDestinationQueries.getDreamDestinations),
        variables: {'user_id': widget.userId},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (!result.hasException) {
      final data = result.data?['dreamDestinations'] ?? [];
      setState(() {
        destinations = List<Map<String, String>>.from(
          data.map(
            (e) => {
              'id': e['id'].toString(),
              'name': e['name'].toString(),
              'image': e['image'].toString(),
            },
          ),
        );
      });
    } else {
      print(result.exception.toString());
    }
  }

  Future<void> _showDestinationDialog({
    Map<String, String>? existing,
    int? index,
  }) async {
    TextEditingController nameController = TextEditingController(
      text: existing?['name'],
    );
    File? localPickedImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                constraints: BoxConstraints(maxHeight: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      index != null
                          ? "Edit Destinasi"
                          : "Tambah Destinasi Baru",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Nama Destinasi',
                        prefixIcon: Icon(Icons.location_on),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            localPickedImage = File(picked.path);
                          });
                        }
                      },
                      child: Container(
                        height: 250,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:
                            localPickedImage != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    localPickedImage!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  ),
                                )
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "Pilih Gambar",
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            "Batal",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () async {
                            if ((localPickedImage != null ||
                                    (existing?['image']?.startsWith(
                                          'assets/',
                                        ) ??
                                        false)) &&
                                nameController.text.isNotEmpty) {
                              final newData = {
                                'image':
                                    localPickedImage?.path ??
                                    existing!['image']!,
                                'name': nameController.text,
                              };

                              if (index != null) {
                                setState(() {
                                  destinations[index] = newData;
                                });

                                await editDreamDestination(
                                  id: int.parse(
                                    existing!['id']!,
                                  ), // sesuaikan jika ID asli tersedia di list
                                  name: nameController.text,
                                  newImageFile: localPickedImage,
                                  existingBase64Image: existing?['image'],
                                );
                                Navigator.of(context).pop();
                              } else {
                                await addDreamDestination(
                                  // <<< pakai await
                                  nameController.text,
                                  localPickedImage!,
                                );
                                Navigator.of(
                                  context,
                                ).pop(); // <<< tutup dialog setelah selesai
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Nama dan gambar harus diisi"),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF225B75),
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Simpan",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showActionOptions(int index) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: Icon(Icons.edit),
                  title: Text("Edit"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDestinationDialog(
                      existing: destinations[index],
                      index: index,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete),
                  title: Text("Hapus"),
                  onTap: () async {
                    final id = int.tryParse(destinations[index]['id'] ?? '');
                    if (id != null) {
                      await deleteDreamDestination(id);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 102, 141),
      body: Column(
        children: [
          SizedBox(height: 60),
          Center(
            child: Text(
              'Destinasi Impian',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 25),
          Expanded(
            child: PageView.builder(
              itemCount: destinations.length + 1,
              controller: PageController(viewportFraction: 0.7),
              itemBuilder: (context, index) {
                if (index < destinations.length) {
                  final item = destinations[index];
                  final imagePath = item['image']!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: GestureDetector(
                      onTap: () => _showActionOptions(index),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height:
                                  600, // ganti dari 600 jadi lebih kecil agar aman
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child:
                                    imagePath.isNotEmpty
                                        ? Builder(
                                          builder: (context) {
                                            try {
                                              return Image.memory(
                                                base64Decode(imagePath),
                                                height: 600,
                                                fit: BoxFit.cover,
                                              );
                                            } catch (e) {
                                              return Container(
                                                height: 600,
                                                color: const Color.fromARGB(
                                                  255,
                                                  148,
                                                  148,
                                                  148,
                                                ),
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.white,
                                                ),
                                              );
                                            }
                                          },
                                        )
                                        : Container(
                                          height: 600,
                                          color: const Color.fromARGB(
                                            255,
                                            148,
                                            148,
                                            148,
                                          ),
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              item['name']!,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Card tambah destinasi
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Center(
                      // Tambahkan ini agar kontennya berada di tengah
                      child: Column(
                        mainAxisSize:
                            MainAxisSize
                                .min, // Supaya tinggi column menyesuaikan
                        children: [
                          GestureDetector(
                            onTap: () => _showDestinationDialog(),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 370,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.add,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tambah Lokasi',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
