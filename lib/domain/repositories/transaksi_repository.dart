import '../entities/transaksi.dart';

abstract class TransaksiRepository {
  List<Transaksi> getTransaksi();
  Future<void> addTransaksi(Transaksi transaksi);
  Future<void> updateTransaksi(dynamic key, Transaksi transaksi);
  Future<void> deleteTransaksi(dynamic keyOrId);
}
