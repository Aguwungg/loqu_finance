import '../entities/program.dart';

abstract class ProgramRepository {
  List<Program> getPrograms();
  Future<void> addProgram(Program program);
  Future<void> updateProgram(Program program);
  Future<void> deleteProgram(String id);
}
