// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $StudySetsTable extends StudySets
    with TableInfo<$StudySetsTable, StudySet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudySetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('text'),
  );
  static const VerificationMeta _sourceTextMeta = const VerificationMeta(
    'sourceText',
  );
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
    'source_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _sourcePathsMeta = const VerificationMeta(
    'sourcePaths',
  );
  @override
  late final GeneratedColumn<String> sourcePaths = GeneratedColumn<String>(
    'source_paths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    sourceType,
    sourceText,
    sourcePaths,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudySet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('source_text')) {
      context.handle(
        _sourceTextMeta,
        sourceText.isAcceptableOrUnknown(data['source_text']!, _sourceTextMeta),
      );
    }
    if (data.containsKey('source_paths')) {
      context.handle(
        _sourcePathsMeta,
        sourcePaths.isAcceptableOrUnknown(
          data['source_paths']!,
          _sourcePathsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudySet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudySet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_text'],
      )!,
      sourcePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_paths'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StudySetsTable createAlias(String alias) {
    return $StudySetsTable(attachedDatabase, alias);
  }
}

class StudySet extends DataClass implements Insertable<StudySet> {
  final int id;
  final String title;
  final String sourceType;
  final String sourceText;
  final String sourcePaths;
  final DateTime createdAt;
  const StudySet({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.sourceText,
    required this.sourcePaths,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['source_type'] = Variable<String>(sourceType);
    map['source_text'] = Variable<String>(sourceText);
    map['source_paths'] = Variable<String>(sourcePaths);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StudySetsCompanion toCompanion(bool nullToAbsent) {
    return StudySetsCompanion(
      id: Value(id),
      title: Value(title),
      sourceType: Value(sourceType),
      sourceText: Value(sourceText),
      sourcePaths: Value(sourcePaths),
      createdAt: Value(createdAt),
    );
  }

  factory StudySet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudySet(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceText: serializer.fromJson<String>(json['sourceText']),
      sourcePaths: serializer.fromJson<String>(json['sourcePaths']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceText': serializer.toJson<String>(sourceText),
      'sourcePaths': serializer.toJson<String>(sourcePaths),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StudySet copyWith({
    int? id,
    String? title,
    String? sourceType,
    String? sourceText,
    String? sourcePaths,
    DateTime? createdAt,
  }) => StudySet(
    id: id ?? this.id,
    title: title ?? this.title,
    sourceType: sourceType ?? this.sourceType,
    sourceText: sourceText ?? this.sourceText,
    sourcePaths: sourcePaths ?? this.sourcePaths,
    createdAt: createdAt ?? this.createdAt,
  );
  StudySet copyWithCompanion(StudySetsCompanion data) {
    return StudySet(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceText: data.sourceText.present
          ? data.sourceText.value
          : this.sourceText,
      sourcePaths: data.sourcePaths.present
          ? data.sourcePaths.value
          : this.sourcePaths,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudySet(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceText: $sourceText, ')
          ..write('sourcePaths: $sourcePaths, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, sourceType, sourceText, sourcePaths, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySet &&
          other.id == this.id &&
          other.title == this.title &&
          other.sourceType == this.sourceType &&
          other.sourceText == this.sourceText &&
          other.sourcePaths == this.sourcePaths &&
          other.createdAt == this.createdAt);
}

class StudySetsCompanion extends UpdateCompanion<StudySet> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> sourceType;
  final Value<String> sourceText;
  final Value<String> sourcePaths;
  final Value<DateTime> createdAt;
  const StudySetsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.sourcePaths = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StudySetsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.sourceType = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.sourcePaths = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<StudySet> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? sourceType,
    Expression<String>? sourceText,
    Expression<String>? sourcePaths,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceText != null) 'source_text': sourceText,
      if (sourcePaths != null) 'source_paths': sourcePaths,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StudySetsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? sourceType,
    Value<String>? sourceText,
    Value<String>? sourcePaths,
    Value<DateTime>? createdAt,
  }) {
    return StudySetsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      sourceText: sourceText ?? this.sourceText,
      sourcePaths: sourcePaths ?? this.sourcePaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (sourcePaths.present) {
      map['source_paths'] = Variable<String>(sourcePaths.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySetsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceText: $sourceText, ')
          ..write('sourcePaths: $sourcePaths, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuestionRowsTable extends QuestionRows
    with TableInfo<$QuestionRowsTable, QuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studySetIdMeta = const VerificationMeta(
    'studySetId',
  );
  @override
  late final GeneratedColumn<int> studySetId = GeneratedColumn<int>(
    'study_set_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES study_sets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('multiple_choice'),
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _choicesMeta = const VerificationMeta(
    'choices',
  );
  @override
  late final GeneratedColumn<String> choices = GeneratedColumn<String>(
    'choices',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerIndexMeta = const VerificationMeta(
    'answerIndex',
  );
  @override
  late final GeneratedColumn<int> answerIndex = GeneratedColumn<int>(
    'answer_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studySetId,
    type,
    prompt,
    choices,
    answerIndex,
    explanation,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'question_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('study_set_id')) {
      context.handle(
        _studySetIdMeta,
        studySetId.isAcceptableOrUnknown(
          data['study_set_id']!,
          _studySetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studySetIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('choices')) {
      context.handle(
        _choicesMeta,
        choices.isAcceptableOrUnknown(data['choices']!, _choicesMeta),
      );
    } else if (isInserting) {
      context.missing(_choicesMeta);
    }
    if (data.containsKey('answer_index')) {
      context.handle(
        _answerIndexMeta,
        answerIndex.isAcceptableOrUnknown(
          data['answer_index']!,
          _answerIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answerIndexMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studySetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}study_set_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      choices: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choices'],
      )!,
      answerIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answer_index'],
      )!,
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
    );
  }

  @override
  $QuestionRowsTable createAlias(String alias) {
    return $QuestionRowsTable(attachedDatabase, alias);
  }
}

class QuestionRow extends DataClass implements Insertable<QuestionRow> {
  final int id;
  final int studySetId;
  final String type;
  final String prompt;
  final String choices;
  final int answerIndex;
  final String explanation;
  const QuestionRow({
    required this.id,
    required this.studySetId,
    required this.type,
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['study_set_id'] = Variable<int>(studySetId);
    map['type'] = Variable<String>(type);
    map['prompt'] = Variable<String>(prompt);
    map['choices'] = Variable<String>(choices);
    map['answer_index'] = Variable<int>(answerIndex);
    map['explanation'] = Variable<String>(explanation);
    return map;
  }

  QuestionRowsCompanion toCompanion(bool nullToAbsent) {
    return QuestionRowsCompanion(
      id: Value(id),
      studySetId: Value(studySetId),
      type: Value(type),
      prompt: Value(prompt),
      choices: Value(choices),
      answerIndex: Value(answerIndex),
      explanation: Value(explanation),
    );
  }

  factory QuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRow(
      id: serializer.fromJson<int>(json['id']),
      studySetId: serializer.fromJson<int>(json['studySetId']),
      type: serializer.fromJson<String>(json['type']),
      prompt: serializer.fromJson<String>(json['prompt']),
      choices: serializer.fromJson<String>(json['choices']),
      answerIndex: serializer.fromJson<int>(json['answerIndex']),
      explanation: serializer.fromJson<String>(json['explanation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studySetId': serializer.toJson<int>(studySetId),
      'type': serializer.toJson<String>(type),
      'prompt': serializer.toJson<String>(prompt),
      'choices': serializer.toJson<String>(choices),
      'answerIndex': serializer.toJson<int>(answerIndex),
      'explanation': serializer.toJson<String>(explanation),
    };
  }

  QuestionRow copyWith({
    int? id,
    int? studySetId,
    String? type,
    String? prompt,
    String? choices,
    int? answerIndex,
    String? explanation,
  }) => QuestionRow(
    id: id ?? this.id,
    studySetId: studySetId ?? this.studySetId,
    type: type ?? this.type,
    prompt: prompt ?? this.prompt,
    choices: choices ?? this.choices,
    answerIndex: answerIndex ?? this.answerIndex,
    explanation: explanation ?? this.explanation,
  );
  QuestionRow copyWithCompanion(QuestionRowsCompanion data) {
    return QuestionRow(
      id: data.id.present ? data.id.value : this.id,
      studySetId: data.studySetId.present
          ? data.studySetId.value
          : this.studySetId,
      type: data.type.present ? data.type.value : this.type,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      choices: data.choices.present ? data.choices.value : this.choices,
      answerIndex: data.answerIndex.present
          ? data.answerIndex.value
          : this.answerIndex,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRow(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('type: $type, ')
          ..write('prompt: $prompt, ')
          ..write('choices: $choices, ')
          ..write('answerIndex: $answerIndex, ')
          ..write('explanation: $explanation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studySetId,
    type,
    prompt,
    choices,
    answerIndex,
    explanation,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRow &&
          other.id == this.id &&
          other.studySetId == this.studySetId &&
          other.type == this.type &&
          other.prompt == this.prompt &&
          other.choices == this.choices &&
          other.answerIndex == this.answerIndex &&
          other.explanation == this.explanation);
}

class QuestionRowsCompanion extends UpdateCompanion<QuestionRow> {
  final Value<int> id;
  final Value<int> studySetId;
  final Value<String> type;
  final Value<String> prompt;
  final Value<String> choices;
  final Value<int> answerIndex;
  final Value<String> explanation;
  const QuestionRowsCompanion({
    this.id = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.type = const Value.absent(),
    this.prompt = const Value.absent(),
    this.choices = const Value.absent(),
    this.answerIndex = const Value.absent(),
    this.explanation = const Value.absent(),
  });
  QuestionRowsCompanion.insert({
    this.id = const Value.absent(),
    required int studySetId,
    this.type = const Value.absent(),
    required String prompt,
    required String choices,
    required int answerIndex,
    this.explanation = const Value.absent(),
  }) : studySetId = Value(studySetId),
       prompt = Value(prompt),
       choices = Value(choices),
       answerIndex = Value(answerIndex);
  static Insertable<QuestionRow> custom({
    Expression<int>? id,
    Expression<int>? studySetId,
    Expression<String>? type,
    Expression<String>? prompt,
    Expression<String>? choices,
    Expression<int>? answerIndex,
    Expression<String>? explanation,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studySetId != null) 'study_set_id': studySetId,
      if (type != null) 'type': type,
      if (prompt != null) 'prompt': prompt,
      if (choices != null) 'choices': choices,
      if (answerIndex != null) 'answer_index': answerIndex,
      if (explanation != null) 'explanation': explanation,
    });
  }

  QuestionRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? studySetId,
    Value<String>? type,
    Value<String>? prompt,
    Value<String>? choices,
    Value<int>? answerIndex,
    Value<String>? explanation,
  }) {
    return QuestionRowsCompanion(
      id: id ?? this.id,
      studySetId: studySetId ?? this.studySetId,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      choices: choices ?? this.choices,
      answerIndex: answerIndex ?? this.answerIndex,
      explanation: explanation ?? this.explanation,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studySetId.present) {
      map['study_set_id'] = Variable<int>(studySetId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (choices.present) {
      map['choices'] = Variable<String>(choices.value);
    }
    if (answerIndex.present) {
      map['answer_index'] = Variable<int>(answerIndex.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRowsCompanion(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('type: $type, ')
          ..write('prompt: $prompt, ')
          ..write('choices: $choices, ')
          ..write('answerIndex: $answerIndex, ')
          ..write('explanation: $explanation')
          ..write(')'))
        .toString();
  }
}

class $FlashcardRowsTable extends FlashcardRows
    with TableInfo<$FlashcardRowsTable, FlashcardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studySetIdMeta = const VerificationMeta(
    'studySetId',
  );
  @override
  late final GeneratedColumn<int> studySetId = GeneratedColumn<int>(
    'study_set_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES study_sets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, studySetId, front, back];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcard_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlashcardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('study_set_id')) {
      context.handle(
        _studySetIdMeta,
        studySetId.isAcceptableOrUnknown(
          data['study_set_id']!,
          _studySetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studySetIdMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlashcardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlashcardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studySetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}study_set_id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
    );
  }

  @override
  $FlashcardRowsTable createAlias(String alias) {
    return $FlashcardRowsTable(attachedDatabase, alias);
  }
}

class FlashcardRow extends DataClass implements Insertable<FlashcardRow> {
  final int id;
  final int studySetId;
  final String front;
  final String back;
  const FlashcardRow({
    required this.id,
    required this.studySetId,
    required this.front,
    required this.back,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['study_set_id'] = Variable<int>(studySetId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    return map;
  }

  FlashcardRowsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardRowsCompanion(
      id: Value(id),
      studySetId: Value(studySetId),
      front: Value(front),
      back: Value(back),
    );
  }

  factory FlashcardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlashcardRow(
      id: serializer.fromJson<int>(json['id']),
      studySetId: serializer.fromJson<int>(json['studySetId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studySetId': serializer.toJson<int>(studySetId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
    };
  }

  FlashcardRow copyWith({
    int? id,
    int? studySetId,
    String? front,
    String? back,
  }) => FlashcardRow(
    id: id ?? this.id,
    studySetId: studySetId ?? this.studySetId,
    front: front ?? this.front,
    back: back ?? this.back,
  );
  FlashcardRow copyWithCompanion(FlashcardRowsCompanion data) {
    return FlashcardRow(
      id: data.id.present ? data.id.value : this.id,
      studySetId: data.studySetId.present
          ? data.studySetId.value
          : this.studySetId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardRow(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('front: $front, ')
          ..write('back: $back')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studySetId, front, back);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardRow &&
          other.id == this.id &&
          other.studySetId == this.studySetId &&
          other.front == this.front &&
          other.back == this.back);
}

class FlashcardRowsCompanion extends UpdateCompanion<FlashcardRow> {
  final Value<int> id;
  final Value<int> studySetId;
  final Value<String> front;
  final Value<String> back;
  const FlashcardRowsCompanion({
    this.id = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
  });
  FlashcardRowsCompanion.insert({
    this.id = const Value.absent(),
    required int studySetId,
    required String front,
    required String back,
  }) : studySetId = Value(studySetId),
       front = Value(front),
       back = Value(back);
  static Insertable<FlashcardRow> custom({
    Expression<int>? id,
    Expression<int>? studySetId,
    Expression<String>? front,
    Expression<String>? back,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studySetId != null) 'study_set_id': studySetId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
    });
  }

  FlashcardRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? studySetId,
    Value<String>? front,
    Value<String>? back,
  }) {
    return FlashcardRowsCompanion(
      id: id ?? this.id,
      studySetId: studySetId ?? this.studySetId,
      front: front ?? this.front,
      back: back ?? this.back,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studySetId.present) {
      map['study_set_id'] = Variable<int>(studySetId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardRowsCompanion(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('front: $front, ')
          ..write('back: $back')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts with TableInfo<$AttemptsTable, Attempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _studySetIdMeta = const VerificationMeta(
    'studySetId',
  );
  @override
  late final GeneratedColumn<int> studySetId = GeneratedColumn<int>(
    'study_set_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES study_sets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultsMeta = const VerificationMeta(
    'results',
  );
  @override
  late final GeneratedColumn<String> results = GeneratedColumn<String>(
    'results',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    studySetId,
    score,
    total,
    durationSeconds,
    results,
    takenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('study_set_id')) {
      context.handle(
        _studySetIdMeta,
        studySetId.isAcceptableOrUnknown(
          data['study_set_id']!,
          _studySetIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_studySetIdMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('results')) {
      context.handle(
        _resultsMeta,
        results.isAcceptableOrUnknown(data['results']!, _resultsMeta),
      );
    } else if (isInserting) {
      context.missing(_resultsMeta);
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studySetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}study_set_id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      results: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}results'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class Attempt extends DataClass implements Insertable<Attempt> {
  final int id;
  final int studySetId;
  final int score;
  final int total;
  final int durationSeconds;
  final String results;
  final DateTime takenAt;
  const Attempt({
    required this.id,
    required this.studySetId,
    required this.score,
    required this.total,
    required this.durationSeconds,
    required this.results,
    required this.takenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['study_set_id'] = Variable<int>(studySetId);
    map['score'] = Variable<int>(score);
    map['total'] = Variable<int>(total);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['results'] = Variable<String>(results);
    map['taken_at'] = Variable<DateTime>(takenAt);
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      studySetId: Value(studySetId),
      score: Value(score),
      total: Value(total),
      durationSeconds: Value(durationSeconds),
      results: Value(results),
      takenAt: Value(takenAt),
    );
  }

  factory Attempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attempt(
      id: serializer.fromJson<int>(json['id']),
      studySetId: serializer.fromJson<int>(json['studySetId']),
      score: serializer.fromJson<int>(json['score']),
      total: serializer.fromJson<int>(json['total']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      results: serializer.fromJson<String>(json['results']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studySetId': serializer.toJson<int>(studySetId),
      'score': serializer.toJson<int>(score),
      'total': serializer.toJson<int>(total),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'results': serializer.toJson<String>(results),
      'takenAt': serializer.toJson<DateTime>(takenAt),
    };
  }

  Attempt copyWith({
    int? id,
    int? studySetId,
    int? score,
    int? total,
    int? durationSeconds,
    String? results,
    DateTime? takenAt,
  }) => Attempt(
    id: id ?? this.id,
    studySetId: studySetId ?? this.studySetId,
    score: score ?? this.score,
    total: total ?? this.total,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    results: results ?? this.results,
    takenAt: takenAt ?? this.takenAt,
  );
  Attempt copyWithCompanion(AttemptsCompanion data) {
    return Attempt(
      id: data.id.present ? data.id.value : this.id,
      studySetId: data.studySetId.present
          ? data.studySetId.value
          : this.studySetId,
      score: data.score.present ? data.score.value : this.score,
      total: data.total.present ? data.total.value : this.total,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      results: data.results.present ? data.results.value : this.results,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attempt(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('score: $score, ')
          ..write('total: $total, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('results: $results, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studySetId,
    score,
    total,
    durationSeconds,
    results,
    takenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attempt &&
          other.id == this.id &&
          other.studySetId == this.studySetId &&
          other.score == this.score &&
          other.total == this.total &&
          other.durationSeconds == this.durationSeconds &&
          other.results == this.results &&
          other.takenAt == this.takenAt);
}

class AttemptsCompanion extends UpdateCompanion<Attempt> {
  final Value<int> id;
  final Value<int> studySetId;
  final Value<int> score;
  final Value<int> total;
  final Value<int> durationSeconds;
  final Value<String> results;
  final Value<DateTime> takenAt;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.score = const Value.absent(),
    this.total = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.results = const Value.absent(),
    this.takenAt = const Value.absent(),
  });
  AttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int studySetId,
    required int score,
    required int total,
    required int durationSeconds,
    required String results,
    this.takenAt = const Value.absent(),
  }) : studySetId = Value(studySetId),
       score = Value(score),
       total = Value(total),
       durationSeconds = Value(durationSeconds),
       results = Value(results);
  static Insertable<Attempt> custom({
    Expression<int>? id,
    Expression<int>? studySetId,
    Expression<int>? score,
    Expression<int>? total,
    Expression<int>? durationSeconds,
    Expression<String>? results,
    Expression<DateTime>? takenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studySetId != null) 'study_set_id': studySetId,
      if (score != null) 'score': score,
      if (total != null) 'total': total,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (results != null) 'results': results,
      if (takenAt != null) 'taken_at': takenAt,
    });
  }

  AttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? studySetId,
    Value<int>? score,
    Value<int>? total,
    Value<int>? durationSeconds,
    Value<String>? results,
    Value<DateTime>? takenAt,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      studySetId: studySetId ?? this.studySetId,
      score: score ?? this.score,
      total: total ?? this.total,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      results: results ?? this.results,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studySetId.present) {
      map['study_set_id'] = Variable<int>(studySetId.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (results.present) {
      map['results'] = Variable<String>(results.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('score: $score, ')
          ..write('total: $total, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('results: $results, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StudySetsTable studySets = $StudySetsTable(this);
  late final $QuestionRowsTable questionRows = $QuestionRowsTable(this);
  late final $FlashcardRowsTable flashcardRows = $FlashcardRowsTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    studySets,
    questionRows,
    flashcardRows,
    attempts,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'study_sets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('question_rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'study_sets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('flashcard_rows', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'study_sets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('attempts', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$StudySetsTableCreateCompanionBuilder = StudySetsCompanion Function({
  Value<int> id,
  required String title,
  Value<String> sourceType,
  Value<String> sourceText,
  Value<String> sourcePaths,
  Value<DateTime> createdAt,
});
typedef $$StudySetsTableUpdateCompanionBuilder = StudySetsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> sourceType,
  Value<String> sourceText,
  Value<String> sourcePaths,
  Value<DateTime> createdAt,
});

final class $$StudySetsTableReferences
    extends BaseReferences<_$AppDatabase, $StudySetsTable, StudySet> {
  $$StudySetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QuestionRowsTable, List<QuestionRow>>
  _questionRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.questionRows,
    aliasName: 'study_sets__id__question_rows__study_set_id',
  );

  $$QuestionRowsTableProcessedTableManager get questionRowsRefs {
    final manager = $$QuestionRowsTableTableManager(
      $_db,
      $_db.questionRows,
    ).filter((f) => f.studySetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FlashcardRowsTable, List<FlashcardRow>>
  _flashcardRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.flashcardRows,
    aliasName: 'study_sets__id__flashcard_rows__study_set_id',
  );

  $$FlashcardRowsTableProcessedTableManager get flashcardRowsRefs {
    final manager = $$FlashcardRowsTableTableManager(
      $_db,
      $_db.flashcardRows,
    ).filter((f) => f.studySetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_flashcardRowsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AttemptsTable, List<Attempt>> _attemptsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.attempts,
    aliasName: 'study_sets__id__attempts__study_set_id',
  );

  $$AttemptsTableProcessedTableManager get attemptsRefs {
    final manager = $$AttemptsTableTableManager(
      $_db,
      $_db.attempts,
    ).filter((f) => f.studySetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_attemptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StudySetsTableFilterComposer
    extends Composer<_$AppDatabase, $StudySetsTable> {
  $$StudySetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePaths => $composableBuilder(
    column: $table.sourcePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> questionRowsRefs(
    Expression<bool> Function($$QuestionRowsTableFilterComposer f) f,
  ) {
    final $$QuestionRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionRows,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionRowsTableFilterComposer(
            $db: $db,
            $table: $db.questionRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> flashcardRowsRefs(
    Expression<bool> Function($$FlashcardRowsTableFilterComposer f) f,
  ) {
    final $$FlashcardRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcardRows,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardRowsTableFilterComposer(
            $db: $db,
            $table: $db.flashcardRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attemptsRefs(
    Expression<bool> Function($$AttemptsTableFilterComposer f) f,
  ) {
    final $$AttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableFilterComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudySetsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudySetsTable> {
  $$StudySetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePaths => $composableBuilder(
    column: $table.sourcePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudySetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudySetsTable> {
  $$StudySetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcePaths => $composableBuilder(
    column: $table.sourcePaths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> questionRowsRefs<T extends Object>(
    Expression<T> Function($$QuestionRowsTableAnnotationComposer a) f,
  ) {
    final $$QuestionRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questionRows,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.questionRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> flashcardRowsRefs<T extends Object>(
    Expression<T> Function($$FlashcardRowsTableAnnotationComposer a) f,
  ) {
    final $$FlashcardRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.flashcardRows,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FlashcardRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.flashcardRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> attemptsRefs<T extends Object>(
    Expression<T> Function($$AttemptsTableAnnotationComposer a) f,
  ) {
    final $$AttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StudySetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudySetsTable,
          StudySet,
          $$StudySetsTableFilterComposer,
          $$StudySetsTableOrderingComposer,
          $$StudySetsTableAnnotationComposer,
          $$StudySetsTableCreateCompanionBuilder,
          $$StudySetsTableUpdateCompanionBuilder,
          (StudySet, $$StudySetsTableReferences),
          StudySet,
          PrefetchHooks Function({
            bool questionRowsRefs,
            bool flashcardRowsRefs,
            bool attemptsRefs,
          })
        > {
  $$StudySetsTableTableManager(_$AppDatabase db, $StudySetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudySetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudySetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudySetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceText = const Value.absent(),
                Value<String> sourcePaths = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StudySetsCompanion(
                id: id,
                title: title,
                sourceType: sourceType,
                sourceText: sourceText,
                sourcePaths: sourcePaths,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceText = const Value.absent(),
                Value<String> sourcePaths = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StudySetsCompanion.insert(
                id: id,
                title: title,
                sourceType: sourceType,
                sourceText: sourceText,
                sourcePaths: sourcePaths,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StudySetsTable, StudySet>(table),
                  $$StudySetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                questionRowsRefs = false,
                flashcardRowsRefs = false,
                attemptsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questionRowsRefs) db.questionRows,
                    if (flashcardRowsRefs) db.flashcardRows,
                    if (attemptsRefs) db.attempts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (questionRowsRefs)
                        await $_getPrefetchedData<
                          StudySet,
                          $StudySetsTable,
                          QuestionRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudySetsTableReferences
                              ._questionRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudySetsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studySetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (flashcardRowsRefs)
                        await $_getPrefetchedData<
                          StudySet,
                          $StudySetsTable,
                          FlashcardRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudySetsTableReferences
                              ._flashcardRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudySetsTableReferences(
                                db,
                                table,
                                p0,
                              ).flashcardRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studySetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attemptsRefs)
                        await $_getPrefetchedData<
                          StudySet,
                          $StudySetsTable,
                          Attempt
                        >(
                          currentTable: table,
                          referencedTable: $$StudySetsTableReferences
                              ._attemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudySetsTableReferences(
                                db,
                                table,
                                p0,
                              ).attemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studySetId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StudySetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudySetsTable,
      StudySet,
      $$StudySetsTableFilterComposer,
      $$StudySetsTableOrderingComposer,
      $$StudySetsTableAnnotationComposer,
      $$StudySetsTableCreateCompanionBuilder,
      $$StudySetsTableUpdateCompanionBuilder,
      (StudySet, $$StudySetsTableReferences),
      StudySet,
      PrefetchHooks Function({
        bool questionRowsRefs,
        bool flashcardRowsRefs,
        bool attemptsRefs,
      })
    >;
typedef $$QuestionRowsTableCreateCompanionBuilder =
    QuestionRowsCompanion Function({
      Value<int> id,
      required int studySetId,
      Value<String> type,
      required String prompt,
      required String choices,
      required int answerIndex,
      Value<String> explanation,
    });
typedef $$QuestionRowsTableUpdateCompanionBuilder =
    QuestionRowsCompanion Function({
      Value<int> id,
      Value<int> studySetId,
      Value<String> type,
      Value<String> prompt,
      Value<String> choices,
      Value<int> answerIndex,
      Value<String> explanation,
    });

final class $$QuestionRowsTableReferences
    extends BaseReferences<_$AppDatabase, $QuestionRowsTable, QuestionRow> {
  $$QuestionRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StudySetsTable _studySetIdTable(_$AppDatabase db) =>
      db.studySets.createAlias('question_rows__study_set_id__study_sets__id');

  $$StudySetsTableProcessedTableManager get studySetId {
    final $_column = $_itemColumn<int>('study_set_id')!;

    final manager = $$StudySetsTableTableManager(
      $_db,
      $_db.studySets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studySetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionRowsTable> {
  $$QuestionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choices => $composableBuilder(
    column: $table.choices,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get answerIndex => $composableBuilder(
    column: $table.answerIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  $$StudySetsTableFilterComposer get studySetId {
    final $$StudySetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableFilterComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionRowsTable> {
  $$QuestionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choices => $composableBuilder(
    column: $table.choices,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answerIndex => $composableBuilder(
    column: $table.answerIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudySetsTableOrderingComposer get studySetId {
    final $$StudySetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableOrderingComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionRowsTable> {
  $$QuestionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get choices =>
      $composableBuilder(column: $table.choices, builder: (column) => column);

  GeneratedColumn<int> get answerIndex => $composableBuilder(
    column: $table.answerIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  $$StudySetsTableAnnotationComposer get studySetId {
    final $$StudySetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableAnnotationComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuestionRowsTable,
          QuestionRow,
          $$QuestionRowsTableFilterComposer,
          $$QuestionRowsTableOrderingComposer,
          $$QuestionRowsTableAnnotationComposer,
          $$QuestionRowsTableCreateCompanionBuilder,
          $$QuestionRowsTableUpdateCompanionBuilder,
          (QuestionRow, $$QuestionRowsTableReferences),
          QuestionRow,
          PrefetchHooks Function({bool studySetId})
        > {
  $$QuestionRowsTableTableManager(_$AppDatabase db, $QuestionRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studySetId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> choices = const Value.absent(),
                Value<int> answerIndex = const Value.absent(),
                Value<String> explanation = const Value.absent(),
              }) => QuestionRowsCompanion(
                id: id,
                studySetId: studySetId,
                type: type,
                prompt: prompt,
                choices: choices,
                answerIndex: answerIndex,
                explanation: explanation,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studySetId,
                Value<String> type = const Value.absent(),
                required String prompt,
                required String choices,
                required int answerIndex,
                Value<String> explanation = const Value.absent(),
              }) => QuestionRowsCompanion.insert(
                id: id,
                studySetId: studySetId,
                type: type,
                prompt: prompt,
                choices: choices,
                answerIndex: answerIndex,
                explanation: explanation,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuestionRowsTable, QuestionRow>(table),
                  $$QuestionRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studySetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studySetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.studySetId,
                        referencedTable: $$QuestionRowsTableReferences
                            ._studySetIdTable(db),
                        referencedColumn: $$QuestionRowsTableReferences
                            ._studySetIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuestionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuestionRowsTable,
      QuestionRow,
      $$QuestionRowsTableFilterComposer,
      $$QuestionRowsTableOrderingComposer,
      $$QuestionRowsTableAnnotationComposer,
      $$QuestionRowsTableCreateCompanionBuilder,
      $$QuestionRowsTableUpdateCompanionBuilder,
      (QuestionRow, $$QuestionRowsTableReferences),
      QuestionRow,
      PrefetchHooks Function({bool studySetId})
    >;
typedef $$FlashcardRowsTableCreateCompanionBuilder =
    FlashcardRowsCompanion Function({
      Value<int> id,
      required int studySetId,
      required String front,
      required String back,
    });
typedef $$FlashcardRowsTableUpdateCompanionBuilder =
    FlashcardRowsCompanion Function({
      Value<int> id,
      Value<int> studySetId,
      Value<String> front,
      Value<String> back,
    });

final class $$FlashcardRowsTableReferences
    extends BaseReferences<_$AppDatabase, $FlashcardRowsTable, FlashcardRow> {
  $$FlashcardRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudySetsTable _studySetIdTable(_$AppDatabase db) =>
      db.studySets.createAlias('flashcard_rows__study_set_id__study_sets__id');

  $$StudySetsTableProcessedTableManager get studySetId {
    final $_column = $_itemColumn<int>('study_set_id')!;

    final manager = $$StudySetsTableTableManager(
      $_db,
      $_db.studySets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studySetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FlashcardRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardRowsTable> {
  $$FlashcardRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  $$StudySetsTableFilterComposer get studySetId {
    final $$StudySetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableFilterComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardRowsTable> {
  $$FlashcardRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudySetsTableOrderingComposer get studySetId {
    final $$StudySetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableOrderingComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardRowsTable> {
  $$FlashcardRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  $$StudySetsTableAnnotationComposer get studySetId {
    final $$StudySetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableAnnotationComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FlashcardRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardRowsTable,
          FlashcardRow,
          $$FlashcardRowsTableFilterComposer,
          $$FlashcardRowsTableOrderingComposer,
          $$FlashcardRowsTableAnnotationComposer,
          $$FlashcardRowsTableCreateCompanionBuilder,
          $$FlashcardRowsTableUpdateCompanionBuilder,
          (FlashcardRow, $$FlashcardRowsTableReferences),
          FlashcardRow,
          PrefetchHooks Function({bool studySetId})
        > {
  $$FlashcardRowsTableTableManager(_$AppDatabase db, $FlashcardRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studySetId = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
              }) => FlashcardRowsCompanion(
                id: id,
                studySetId: studySetId,
                front: front,
                back: back,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studySetId,
                required String front,
                required String back,
              }) => FlashcardRowsCompanion.insert(
                id: id,
                studySetId: studySetId,
                front: front,
                back: back,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlashcardRowsTable, FlashcardRow>(table),
                  $$FlashcardRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studySetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studySetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.studySetId,
                        referencedTable: $$FlashcardRowsTableReferences
                            ._studySetIdTable(db),
                        referencedColumn: $$FlashcardRowsTableReferences
                            ._studySetIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FlashcardRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardRowsTable,
      FlashcardRow,
      $$FlashcardRowsTableFilterComposer,
      $$FlashcardRowsTableOrderingComposer,
      $$FlashcardRowsTableAnnotationComposer,
      $$FlashcardRowsTableCreateCompanionBuilder,
      $$FlashcardRowsTableUpdateCompanionBuilder,
      (FlashcardRow, $$FlashcardRowsTableReferences),
      FlashcardRow,
      PrefetchHooks Function({bool studySetId})
    >;
typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  required int studySetId,
  required int score,
  required int total,
  required int durationSeconds,
  required String results,
  Value<DateTime> takenAt,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<int> id,
  Value<int> studySetId,
  Value<int> score,
  Value<int> total,
  Value<int> durationSeconds,
  Value<String> results,
  Value<DateTime> takenAt,
});

final class $$AttemptsTableReferences
    extends BaseReferences<_$AppDatabase, $AttemptsTable, Attempt> {
  $$AttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StudySetsTable _studySetIdTable(_$AppDatabase db) =>
      db.studySets.createAlias('attempts__study_set_id__study_sets__id');

  $$StudySetsTableProcessedTableManager get studySetId {
    final $_column = $_itemColumn<int>('study_set_id')!;

    final manager = $$StudySetsTableTableManager(
      $_db,
      $_db.studySets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_studySetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get results => $composableBuilder(
    column: $table.results,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StudySetsTableFilterComposer get studySetId {
    final $$StudySetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableFilterComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get results => $composableBuilder(
    column: $table.results,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StudySetsTableOrderingComposer get studySetId {
    final $$StudySetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableOrderingComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get results =>
      $composableBuilder(column: $table.results, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  $$StudySetsTableAnnotationComposer get studySetId {
    final $$StudySetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.studySetId,
      referencedTable: $db.studySets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StudySetsTableAnnotationComposer(
            $db: $db,
            $table: $db.studySets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttemptsTable,
          Attempt,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (Attempt, $$AttemptsTableReferences),
          Attempt,
          PrefetchHooks Function({bool studySetId})
        > {
  $$AttemptsTableTableManager(_$AppDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studySetId = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String> results = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                studySetId: studySetId,
                score: score,
                total: total,
                durationSeconds: durationSeconds,
                results: results,
                takenAt: takenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studySetId,
                required int score,
                required int total,
                required int durationSeconds,
                required String results,
                Value<DateTime> takenAt = const Value.absent(),
              }) => AttemptsCompanion.insert(
                id: id,
                studySetId: studySetId,
                score: score,
                total: total,
                durationSeconds: durationSeconds,
                results: results,
                takenAt: takenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptsTable, Attempt>(table),
                  $$AttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({studySetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (studySetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.studySetId,
                        referencedTable: $$AttemptsTableReferences
                            ._studySetIdTable(db),
                        referencedColumn: $$AttemptsTableReferences
                            ._studySetIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttemptsTable,
      Attempt,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (Attempt, $$AttemptsTableReferences),
      Attempt,
      PrefetchHooks Function({bool studySetId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StudySetsTableTableManager get studySets =>
      $$StudySetsTableTableManager(_db, _db.studySets);
  $$QuestionRowsTableTableManager get questionRows =>
      $$QuestionRowsTableTableManager(_db, _db.questionRows);
  $$FlashcardRowsTableTableManager get flashcardRows =>
      $$FlashcardRowsTableTableManager(_db, _db.flashcardRows);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
}
