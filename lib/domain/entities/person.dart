import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 1)
class Person extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nama;

  @HiveField(2)
  String kategori; // Isi dengan 'Pengajar' atau 'Murid'

  Person({
    required this.id,
    required this.nama,
    required this.kategori,
  });
}
