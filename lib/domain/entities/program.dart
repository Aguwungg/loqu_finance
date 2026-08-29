import 'package:hive/hive.dart';

part 'program.g.dart';

@HiveType(typeId: 0)
class Program extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String namaProgram;

  @HiveField(2)
  int defaultFeePengajar;

  @HiveField(3)
  int defaultHargaKlien;

  Program({
    required this.id,
    required this.namaProgram,
    required this.defaultFeePengajar,
    required this.defaultHargaKlien,
  });
}