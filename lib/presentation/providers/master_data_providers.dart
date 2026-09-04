import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/program.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/program_repository.dart';
import '../../domain/repositories/person_repository.dart';
import '../../data/repositories/program_repository_impl.dart';
import '../../data/repositories/person_repository_impl.dart';

// --- Repositories Providers ---
final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepositoryImpl(Hive.box<Program>('programBox'));
});

final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepositoryImpl(Hive.box<Person>('personBox'));
});

// --- State Notifiers for raw Hive data ---
class ProgramListNotifier extends StateNotifier<List<Program>> {
  final ProgramRepository _repository;

  ProgramListNotifier(this._repository) : super([]) {
    loadPrograms();
  }

  void loadPrograms() {
    state = _repository.getPrograms();
  }

  Future<void> addProgram(Program program) async {
    await _repository.addProgram(program);
    loadPrograms();
  }

  Future<void> updateProgram(Program program) async {
    await _repository.updateProgram(program);
    loadPrograms();
  }

  Future<void> deleteProgram(String id) async {
    await _repository.deleteProgram(id);
    loadPrograms();
  }
}

final programListProvider = StateNotifierProvider<ProgramListNotifier, List<Program>>((ref) {
  final repo = ref.watch(programRepositoryProvider);
  return ProgramListNotifier(repo);
});

class PersonListNotifier extends StateNotifier<List<Person>> {
  final PersonRepository _repository;

  PersonListNotifier(this._repository) : super([]) {
    loadPeople();
  }

  void loadPeople() {
    state = _repository.getPeople();
  }

  Future<void> addPerson(Person person) async {
    await _repository.addPerson(person);
    loadPeople();
  }

  Future<void> updatePerson(Person person) async {
    await _repository.updatePerson(person);
    loadPeople();
  }

  Future<void> deletePerson(String id) async {
    await _repository.deletePerson(id);
    loadPeople();
  }
}

final personListProvider = StateNotifierProvider<PersonListNotifier, List<Person>>((ref) {
  final repo = ref.watch(personRepositoryProvider);
  return PersonListNotifier(repo);
});

// --- Search Query State Providers ---
final programSearchQueryProvider = StateProvider<String>((ref) => '');
final personSearchQueryProvider = StateProvider<String>((ref) => '');

// --- Filtered State Providers ---
final filteredProgramsProvider = Provider<List<Program>>((ref) {
  final programs = ref.watch(programListProvider);
  final query = ref.watch(programSearchQueryProvider).toLowerCase();
  if (query.isEmpty) return programs;
  return programs.where((p) => p.namaProgram.toLowerCase().contains(query)).toList();
});

final pengajarListProvider = Provider<List<Person>>((ref) {
  final people = ref.watch(personListProvider);
  final query = ref.watch(personSearchQueryProvider).toLowerCase();
  final filtered = people.where((p) => p.kategori == 'Pengajar').toList();
  if (query.isEmpty) return filtered;
  return filtered.where((p) => p.nama.toLowerCase().contains(query)).toList();
});

final muridListProvider = Provider<List<Person>>((ref) {
  final people = ref.watch(personListProvider);
  final query = ref.watch(personSearchQueryProvider).toLowerCase();
  final filtered = people.where((p) => p.kategori == 'Murid').toList();
  if (query.isEmpty) return filtered;
  return filtered.where((p) => p.nama.toLowerCase().contains(query)).toList();
});

final orangTuaListProvider = Provider<List<Person>>((ref) {
  final people = ref.watch(personListProvider);
  final query = ref.watch(personSearchQueryProvider).toLowerCase();
  final filtered = people.where((p) => p.kategori == 'Orang Tua').toList();
  if (query.isEmpty) return filtered;
  return filtered.where((p) => p.nama.toLowerCase().contains(query)).toList();
});
