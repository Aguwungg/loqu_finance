import '../entities/person.dart';

abstract class PersonRepository {
  List<Person> getPeople();
  Future<void> addPerson(Person person);
  Future<void> updatePerson(Person person);
  Future<void> deletePerson(String id);
}
