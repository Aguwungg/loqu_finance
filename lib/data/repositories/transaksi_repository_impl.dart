import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';
import '../../domain/entities/transaksi.dart';
import '../../domain/repositories/transaksi_repository.dart';

class TransaksiRepositoryImpl implements TransaksiRepository {
  final Box<Transaksi> _box;

  TransaksiRepositoryImpl(this._box);

  @override
  List<Transaksi> getTransaksi() {
    try {
      return _box.values.toList();
    } catch (e, stackTrace) {
      debugPrint('Error getting transaksi from Hive box: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Future<void> addTransaksi(Transaksi transaksi) async {
    try {
      await _box.put(transaksi.id, transaksi);
    } catch (e, stackTrace) {
      debugPrint('Error adding transaksi to Hive: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> updateTransaksi(dynamic key, Transaksi transaksi) async {
    try {
      await _box.put(key, transaksi);
    } catch (e, stackTrace) {
      debugPrint('Error updating transaksi in Hive: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteTransaksi(dynamic keyOrId) async {
    try {
      if (_box.containsKey(keyOrId)) {
        await _box.delete(keyOrId);
      } else {
        // Fallback: cari key yang transaksinya memiliki id cocok
        dynamic targetKey;
        for (final k in _box.keys) {
          final item = _box.get(k);
          if (item != null && item.id == keyOrId.toString()) {
            targetKey = k;
            break;
          }
        }
        if (targetKey != null) {
          await _box.delete(targetKey);
        } else {
          await _box.delete(keyOrId);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error deleting transaksi from Hive: $e\n$stackTrace');
      rethrow;
    }
  }
}
