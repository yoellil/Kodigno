import 'package:drift/drift.dart';

part 'database.g.dart';

class StudySets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get sourceType => text().withDefault(const Constant('text'))(); // image | pdf | docx | text
  TextColumn get sourceText => text().withDefault(const Constant(''))();
  TextColumn get sourcePaths => text().withDefault(const Constant('[]'))(); // JSON list
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('QuestionRow')
class QuestionRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studySetId =>
      integer().references(StudySets, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text().withDefault(const Constant('multiple_choice'))();
  TextColumn get prompt => text()();
  TextColumn get choices => text()(); // JSON list
  IntColumn get answerIndex => integer()();
  TextColumn get explanation => text().withDefault(const Constant(''))();
}

@DataClassName('FlashcardRow')
class FlashcardRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studySetId =>
      integer().references(StudySets, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()();
  TextColumn get back => text()();
}

class Attempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studySetId =>
      integer().references(StudySets, #id, onDelete: KeyAction.cascade)();
  IntColumn get score => integer()();
  IntColumn get total => integer()();
  IntColumn get durationSeconds => integer()();
  TextColumn get results => text()(); // JSON list
  DateTimeColumn get takenAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [StudySets, QuestionRows, FlashcardRows, Attempts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
      );
}
