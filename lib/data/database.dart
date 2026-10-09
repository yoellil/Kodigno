import 'package:drift/drift.dart';

part 'database.g.dart';

class StudySets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get sourceType => text().withDefault(const Constant('text'))(); // image | pdf | docx | text
  TextColumn get sourceText => text().withDefault(const Constant(''))();
  TextColumn get sourcePaths => text().withDefault(const Constant('[]'))(); // JSON list
  TextColumn get summary => text().withDefault(const Constant(''))(); // JSON lesson, '' = none yet
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
  TextColumn get source => text().withDefault(const Constant(''))(); // JSON SourceRef, '' = not looked up
}

@DataClassName('FlashcardRow')
class FlashcardRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studySetId =>
      integer().references(StudySets, #id, onDelete: KeyAction.cascade)();
  TextColumn get front => text()();
  TextColumn get back => text()();
  TextColumn get source => text().withDefault(const Constant(''))(); // JSON SourceRef, '' = not looked up
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

/// Where each flashcard and quiz question stands in the student's practice: its
/// box in the schedule and the day it is next due. A card or question gets a row
/// the first time it is answered.
@DataClassName('ReviewState')
class ReviewStates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()(); // card | question
  IntColumn get itemId => integer()(); // flashcard_rows.id or question_rows.id
  IntColumn get studySetId =>
      integer().references(StudySets, #id, onDelete: KeyAction.cascade)();
  IntColumn get box => integer().withDefault(const Constant(0))(); // 0 = missed or new .. 4 = well known
  DateTimeColumn get dueDay => dateTime().nullable()(); // midnight of the day it is next due
  DateTimeColumn get lastAt => dateTime().nullable()();
  IntColumn get streak => integer().withDefault(const Constant(0))(); // right in a row
  IntColumn get lapses => integer().withDefault(const Constant(0))(); // wrong, in all

  @override
  List<Set<Column>> get uniqueKeys => [
        {kind, itemId}
      ];
}

/// Every answer the student gave to a flashcard or quiz question, in practice or
/// in a quiz. The schedule is worked out from it, and later, so are patterns in
/// what the student gets wrong.
@DataClassName('ReviewEntry')
class ReviewLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()(); // card | question
  IntColumn get itemId => integer()();
  IntColumn get studySetId =>
      integer().references(StudySets, #id, onDelete: KeyAction.cascade)();
  BoolColumn get correct => boolean()();
  IntColumn get chosen => integer().nullable()(); // the choice picked, for a question
  TextColumn get mode => text()(); // quiz | practice
  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();
}

/// One time a student explained a topic of a lesson in their own words, and what
/// the check found. Kept on the device so the student can compare tries.
@DataClassName('TeachBackAttempt')
class TeachBackAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studySetId =>
      integer().references(StudySets, #id, onDelete: KeyAction.cascade)();
  TextColumn get section => text()(); // the topic's heading in the lesson
  IntColumn get sectionIndex => integer().withDefault(const Constant(0))();
  TextColumn get answer => text()();
  IntColumn get covered => integer().withDefault(const Constant(0))();
  IntColumn get partly => integer().withDefault(const Constant(0))();
  IntColumn get total => integer().withDefault(const Constant(0))();
  BoolColumn get copied => boolean().withDefault(const Constant(false))();
  IntColumn get flagCount => integer().withDefault(const Constant(0))();

  /// 'model' if the AI model judged it, 'words' if only a comparison of words did.
  TextColumn get checkedBy => text().withDefault(const Constant('words'))();

  /// JSON list of the positions of ideas the student said they covered after all.
  TextColumn get overruled => text().withDefault(const Constant('[]'))();
  DateTimeColumn get takenAt => dateTime().withDefault(currentDateAndTime)();
}

/// The key ideas of one topic of a lesson, written once by the AI model from the
/// topic's slides and kept, so they are the same on every try.
@DataClassName('TopicConceptRow')
class TopicConcepts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get studySetId =>
      integer().references(StudySets, #id, onDelete: KeyAction.cascade)();
  TextColumn get section => text()(); // the topic's heading in the lesson
  TextColumn get concepts => text()(); // JSON list of sentences
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {studySetId, section}
      ];
}

@DriftDatabase(tables: [StudySets, QuestionRows, FlashcardRows, Attempts, Readers, Stories, ReadingAttempts, SavedWords, ReviewStates, ReviewLog, TeachBackAttempts, TopicConcepts])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // The reading tables, the words-a-minute column, the saved words and the
          // lesson column were added by different people, some at the same version
          // number, so a database of any age has some of them and not others.
          // Each step checks what is already there.
          Future<bool> hasTable(String name) async => (await customSelect(
                  "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
                  variables: [Variable.withString(name)])
              .get())
              .isNotEmpty;
          Future<bool> hasColumn(String table, String column) async =>
              (await customSelect('PRAGMA table_info($table)').get())
                  .any((r) => r.read<String>('name') == column);

          if (!await hasTable('readers')) await m.createTable(readers);
          if (!await hasTable('stories')) await m.createTable(stories);
          if (!await hasTable('reading_attempts')) await m.createTable(readingAttempts);
          if (!await hasColumn('reading_attempts', 'wpm')) {
            await m.addColumn(readingAttempts, readingAttempts.wpm);
          }
          if (!await hasTable('saved_words')) await m.createTable(savedWords);
          if (!await hasColumn('study_sets', 'summary')) {
            await m.addColumn(studySets, studySets.summary);
          }
          if (await hasTable('question_rows') && !await hasColumn('question_rows', 'source')) {
            await m.addColumn(questionRows, questionRows.source);
          }
          if (await hasTable('flashcard_rows') && !await hasColumn('flashcard_rows', 'source')) {
            await m.addColumn(flashcardRows, flashcardRows.source);
          }
          if (!await hasTable('review_states')) await m.createTable(reviewStates);
          if (!await hasTable('review_log')) await m.createTable(reviewLog);
          if (!await hasTable('teach_back_attempts')) await m.createTable(teachBackAttempts);
          if (!await hasColumn('teach_back_attempts', 'checked_by')) {
            await m.addColumn(teachBackAttempts, teachBackAttempts.checkedBy);
          }
          if (!await hasTable('topic_concepts')) await m.createTable(topicConcepts);
        },
        beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
      );
}
