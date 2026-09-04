import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';
import '../../domain/entities/program.dart';
import '../../domain/repositories/program_repository.dart';

class ProgramRepositoryImpl implements ProgramRepository {
  final Box<Program> _box;

  ProgramRepositoryImpl(this._box);

  @override
  List<Program> getPrograms() {
    try {
      return _box.values.toList();
    } catch (e, stackTrace) {
      debugPrint('Error getting programs from Hive: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Future<void> addProgram(Program program) async {
    try {
      await _box.put(program.id, program);
    } catch (e, stackTrace) {
      debugPrint('Error adding program: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> updateProgram(Program program) async {
    try {
      await _box.put(program.id, program);
    } catch (e, stackTrace) {
      debugPrint('Error updating program: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> deleteProgram(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      debugPrint('Error deleting program: $e\n$stackTrace');
      rethrow;
    }
  }
}
