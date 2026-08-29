import 'package:hive/hive.dart';
import '../../domain/entities/transaksi.dart';
import '../../domain/repositories/transaksi_repository.dart';

class TransaksiRepositoryImpl implements TransaksiRepository {
  final Box<Transaksi> _box;

  TransaksiRepositoryImpl(this._box);

  @override
  List<Transaksi> getTransaksi() {
    return _box.values.toList();
  }

  @override
  Future<void> addTransaksi(Transaksi transaksi) async {
    await _box.put(transaksi.id, transaksi);
  }

  @override
  Future<void> updateTransaksi(Transaksi transaksi) async {
    await _box.put(transaksi.id, transaksi);
  }

  @override
  Future<void> deleteTransaksi(String id) async {
    await _box.delete(id);
  }
}
