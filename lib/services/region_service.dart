import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<String>> fetchProvinces() async {
  final response = await http.get(
    Uri.parse('https://www.emsifa.com/api-wilayah-indonesia/api/provinces.json'),
  );

  if (response.statusCode == 200) {
    final List data = jsonDecode(response.body);
    return data.map<String>((item) => item['name'].toString()).toList();
  } else {
    throw Exception('Gagal memuat data provinsi');
  }
}