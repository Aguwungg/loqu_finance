import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 1)
class Person extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nama;

  @HiveField(2)
  String kategori; // Isi dengan 'Pengajar', 'Murid', atau 'Orang Tua'

  @HiveField(3)
  String? parentId; // ID Orang Tua (khusus jika kategori = Murid)

  Person({
    required this.id,
    required this.nama,
    required this.kategori,
    this.parentId,
  });
}
