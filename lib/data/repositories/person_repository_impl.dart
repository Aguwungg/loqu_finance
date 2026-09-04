import 'package:flutter/foundation.dart' show debugPrint;
import 'package:hive/hive.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/person_repository.dart';

class PersonRepositoryImpl implements PersonRepository {
  final Box<Person> _box;

  PersonRepositoryImpl(this._box);

  @override
  List<Person> getPeople() {
    try {
      return _box.values.toList();
    } catch (e, stackTrace) {
      debugPrint('Error getting people from Hive: $e\n$stackTrace');
      return [];
    }
  }

  @override
  Future<void> addPerson(Person person) async {
    try {
      await _box.put(person.id, person);
    } catch (e, stackTrace) {
      debugPrint('Error adding person: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> updatePerson(Person person) async {
    try {
      await _box.put(person.id, person);
    } catch (e, stackTrace) {
      debugPrint('Error updating person: $e\n$stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> deletePerson(String id) async {
    try {
      await _box.delete(id);
    } catch (e, stackTrace) {
      debugPrint('Error deleting person: $e\n$stackTrace');
      rethrow;
    }
  }
}
