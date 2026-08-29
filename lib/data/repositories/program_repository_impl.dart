import 'package:hive/hive.dart';
import '../../domain/entities/program.dart';
import '../../domain/repositories/program_repository.dart';

class ProgramRepositoryImpl implements ProgramRepository {
  final Box<Program> _box;

  ProgramRepositoryImpl(this._box);

  @override
  List<Program> getPrograms() {
    return _box.values.toList();
  }

  @override
  Future<void> addProgram(Program program) async {
    await _box.put(program.id, program);
  }

  @override
  Future<void> updateProgram(Program program) async {
    await _box.put(program.id, program);
  }

  @override
  Future<void> deleteProgram(String id) async {
    await _box.delete(id);
  }
}
