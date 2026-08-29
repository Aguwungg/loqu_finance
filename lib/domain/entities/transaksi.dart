import 'package:hive/hive.dart';

part 'transaksi.g.dart';

@HiveType(typeId: 2)
class Transaksi extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime tanggal;

  @HiveField(2)
  String jenis; // Isi dengan 'Slip Gaji' atau 'Invoice'

  @HiveField(3)
  String namaTarget; // Nama pengajar atau nama orang tua

  @HiveField(4)
  int total; // Total Rp dari dokumen tersebut

  Transaksi({
    required this.id,
    required this.tanggal,
    required this.jenis,
    required this.namaTarget,
    required this.total,
  });
}