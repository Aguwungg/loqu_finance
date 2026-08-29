import 'package:hive/hive.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/person_repository.dart';

class PersonRepositoryImpl implements PersonRepository {
  final Box<Person> _box;

  PersonRepositoryImpl(this._box);

  @override
  List<Person> getPeople() {
    return _box.values.toList();
  }

  @override
  Future<void> addPerson(Person person) async {
    await _box.put(person.id, person);
  }

  @override
  Future<void> updatePerson(Person person) async {
    await _box.put(person.id, person);
  }

  @override
  Future<void> deletePerson(String id) async {
    await _box.delete(id);
  }
}
