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

// ---------- Kulay reading lab ----------

/// A Kulay reader. [level] indexes reading/levels.dart; [placed] = reading check done.
class Readers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()(); // compared case-insensitively in the repository
  IntColumn get level => integer().withDefault(const Constant(0))();
  BoolColumn get placed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A checked story. Shared: any reader at its color can get it.
@DataClassName('StoryRow')
class Stories extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get level => integer()();
  TextColumn get topic => text()();
  TextColumn get title => text()();
  TextColumn get paras => text()(); // JSON list of lists of sentences
  TextColumn get questions => text()(); // JSON list of {question, choices, answer, evidence}
  TextColumn get checks => text().withDefault(const Constant('{}'))(); // JSON
  IntColumn get pipeline => integer()();
  TextColumn get source => text().withDefault(const Constant('ai'))(); // ai | starter
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ReadingAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get readerId => integer().references(Readers, #id, onDelete: KeyAction.cascade)();
  IntColumn get storyId => integer().references(Stories, #id)();
  IntColumn get level => integer()();
  IntColumn get correct => integer()();
  IntColumn get total => integer()();
  IntColumn get moved => integer().withDefault(const Constant(0))(); // -1, 0, +1
  TextColumn get skills => text().withDefault(const Constant('[]'))(); // JSON list of {skill, correct}
  IntColumn get wpm => integer().nullable()(); // words a minute, if the reader timed their reading
  DateTimeColumn get takenAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {readerId, storyId}
      ];
}

/// A word a reader asked about. [known] counts right answers in a row in practice.
class SavedWords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get readerId => integer().references(Readers, #id, onDelete: KeyAction.cascade)();
  TextColumn get word => text()(); // lower case
  TextColumn get meaning => text()();
  TextColumn get synonym => text().nullable()();
  TextColumn get sentence => text()();
  IntColumn get times => integer().withDefault(const Constant(1))();
  IntColumn get known => integer().withDefault(const Constant(0))();
  DateTimeColumn get savedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {readerId, word}
      ];
}

@DriftDatabase(tables: [StudySets, QuestionRows, FlashcardRows, Attempts, Readers, Stories, ReadingAttempts, SavedWords])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(readers);
            await m.createTable(stories);
            await m.createTable(readingAttempts);
          }
          if (from == 2) await m.addColumn(readingAttempts, readingAttempts.wpm); // v1 just made the table with it
          if (from < 3) await m.createTable(savedWords);
        },
        beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
      );
}
