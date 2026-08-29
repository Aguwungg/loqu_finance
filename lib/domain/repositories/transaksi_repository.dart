import '../entities/transaksi.dart';

abstract class TransaksiRepository {
  List<Transaksi> getTransaksi();
  Future<void> addTransaksi(Transaksi transaksi);
  Future<void> updateTransaksi(Transaksi transaksi);
  Future<void> deleteTransaksi(String id);
}
