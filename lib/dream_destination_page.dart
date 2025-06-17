import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class DreamDestinationPage extends StatefulWidget {
  const DreamDestinationPage({super.key});

  @override
  _DreamDestinationPageState createState() => _DreamDestinationPageState();
}

class _DreamDestinationPageState extends State<DreamDestinationPage> {
  List<Map<String, String>> destinations = [];

  Future<void> _showDestinationDialog({
    Map<String, String>? existing,
    int? index,
  }) async {
    TextEditingController nameController = TextEditingController(
      text: existing?['name'],
    );
    File? localPickedImage =
        existing != null && !existing['image']!.startsWith('assets/')
            ? File(existing['image']!)
            : null;

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
                        height: 150,
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
                                    fit: BoxFit.cover,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            "Batal",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
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
                              setState(() {
                                if (index != null) {
                                  destinations[index] = newData;
                                } else {
                                  destinations.add(newData);
                                }
                              });
                              Navigator.of(context).pop();
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
                  onTap: () {
                    setState(() {
                      destinations.removeAt(index);
                    });
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
                  final isAsset = imagePath.startsWith('assets/');

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
                                    isAsset
                                        ? Image.asset(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        )
                                        : Image.file(
                                          File(imagePath),
                                          fit: BoxFit.cover,
                                          width: double.infinity,
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
