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
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    summary,
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
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
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
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
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
  final String summary;
  final DateTime createdAt;
  const StudySet({
    required this.id,
    required this.title,
    required this.sourceType,
    required this.sourceText,
    required this.sourcePaths,
    required this.summary,
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
    map['summary'] = Variable<String>(summary);
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
      summary: Value(summary),
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
      summary: serializer.fromJson<String>(json['summary']),
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
      'summary': serializer.toJson<String>(summary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StudySet copyWith({
    int? id,
    String? title,
    String? sourceType,
    String? sourceText,
    String? sourcePaths,
    String? summary,
    DateTime? createdAt,
  }) => StudySet(
    id: id ?? this.id,
    title: title ?? this.title,
    sourceType: sourceType ?? this.sourceType,
    sourceText: sourceText ?? this.sourceText,
    sourcePaths: sourcePaths ?? this.sourcePaths,
    summary: summary ?? this.summary,
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
      summary: data.summary.present ? data.summary.value : this.summary,
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
          ..write('summary: $summary, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    sourceType,
    sourceText,
    sourcePaths,
    summary,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySet &&
          other.id == this.id &&
          other.title == this.title &&
          other.sourceType == this.sourceType &&
          other.sourceText == this.sourceText &&
          other.sourcePaths == this.sourcePaths &&
          other.summary == this.summary &&
          other.createdAt == this.createdAt);
}

class StudySetsCompanion extends UpdateCompanion<StudySet> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> sourceType;
  final Value<String> sourceText;
  final Value<String> sourcePaths;
  final Value<String> summary;
  final Value<DateTime> createdAt;
  const StudySetsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.sourcePaths = const Value.absent(),
    this.summary = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StudySetsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.sourceType = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.sourcePaths = const Value.absent(),
    this.summary = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<StudySet> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? sourceType,
    Expression<String>? sourceText,
    Expression<String>? sourcePaths,
    Expression<String>? summary,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceText != null) 'source_text': sourceText,
      if (sourcePaths != null) 'source_paths': sourcePaths,
      if (summary != null) 'summary': summary,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StudySetsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? sourceType,
    Value<String>? sourceText,
    Value<String>? sourcePaths,
    Value<String>? summary,
    Value<DateTime>? createdAt,
  }) {
    return StudySetsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceType: sourceType ?? this.sourceType,
      sourceText: sourceText ?? this.sourceText,
      sourcePaths: sourcePaths ?? this.sourcePaths,
      summary: summary ?? this.summary,
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
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
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
          ..write('summary: $summary, ')
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
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
    source,
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
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
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
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
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
  final String source;
  const QuestionRow({
    required this.id,
    required this.studySetId,
    required this.type,
    required this.prompt,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
    required this.source,
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
    map['source'] = Variable<String>(source);
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
      source: Value(source),
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
      source: serializer.fromJson<String>(json['source']),
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
      'source': serializer.toJson<String>(source),
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
    String? source,
  }) => QuestionRow(
    id: id ?? this.id,
    studySetId: studySetId ?? this.studySetId,
    type: type ?? this.type,
    prompt: prompt ?? this.prompt,
    choices: choices ?? this.choices,
    answerIndex: answerIndex ?? this.answerIndex,
    explanation: explanation ?? this.explanation,
    source: source ?? this.source,
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
      source: data.source.present ? data.source.value : this.source,
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
          ..write('explanation: $explanation, ')
          ..write('source: $source')
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
    source,
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
          other.explanation == this.explanation &&
          other.source == this.source);
}

class QuestionRowsCompanion extends UpdateCompanion<QuestionRow> {
  final Value<int> id;
  final Value<int> studySetId;
  final Value<String> type;
  final Value<String> prompt;
  final Value<String> choices;
  final Value<int> answerIndex;
  final Value<String> explanation;
  final Value<String> source;
  const QuestionRowsCompanion({
    this.id = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.type = const Value.absent(),
    this.prompt = const Value.absent(),
    this.choices = const Value.absent(),
    this.answerIndex = const Value.absent(),
    this.explanation = const Value.absent(),
    this.source = const Value.absent(),
  });
  QuestionRowsCompanion.insert({
    this.id = const Value.absent(),
    required int studySetId,
    this.type = const Value.absent(),
    required String prompt,
    required String choices,
    required int answerIndex,
    this.explanation = const Value.absent(),
    this.source = const Value.absent(),
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
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studySetId != null) 'study_set_id': studySetId,
      if (type != null) 'type': type,
      if (prompt != null) 'prompt': prompt,
      if (choices != null) 'choices': choices,
      if (answerIndex != null) 'answer_index': answerIndex,
      if (explanation != null) 'explanation': explanation,
      if (source != null) 'source': source,
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
    Value<String>? source,
  }) {
    return QuestionRowsCompanion(
      id: id ?? this.id,
      studySetId: studySetId ?? this.studySetId,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      choices: choices ?? this.choices,
      answerIndex: answerIndex ?? this.answerIndex,
      explanation: explanation ?? this.explanation,
      source: source ?? this.source,
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
    if (source.present) {
      map['source'] = Variable<String>(source.value);
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
          ..write('explanation: $explanation, ')
          ..write('source: $source')
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
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, studySetId, front, back, source];
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
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
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
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
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
  final String source;
  const FlashcardRow({
    required this.id,
    required this.studySetId,
    required this.front,
    required this.back,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['study_set_id'] = Variable<int>(studySetId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    map['source'] = Variable<String>(source);
    return map;
  }

  FlashcardRowsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardRowsCompanion(
      id: Value(id),
      studySetId: Value(studySetId),
      front: Value(front),
      back: Value(back),
      source: Value(source),
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
      source: serializer.fromJson<String>(json['source']),
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
      'source': serializer.toJson<String>(source),
    };
  }

  FlashcardRow copyWith({
    int? id,
    int? studySetId,
    String? front,
    String? back,
    String? source,
  }) => FlashcardRow(
    id: id ?? this.id,
    studySetId: studySetId ?? this.studySetId,
    front: front ?? this.front,
    back: back ?? this.back,
    source: source ?? this.source,
  );
  FlashcardRow copyWithCompanion(FlashcardRowsCompanion data) {
    return FlashcardRow(
      id: data.id.present ? data.id.value : this.id,
      studySetId: data.studySetId.present
          ? data.studySetId.value
          : this.studySetId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardRow(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studySetId, front, back, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardRow &&
          other.id == this.id &&
          other.studySetId == this.studySetId &&
          other.front == this.front &&
          other.back == this.back &&
          other.source == this.source);
}

class FlashcardRowsCompanion extends UpdateCompanion<FlashcardRow> {
  final Value<int> id;
  final Value<int> studySetId;
  final Value<String> front;
  final Value<String> back;
  final Value<String> source;
  const FlashcardRowsCompanion({
    this.id = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.source = const Value.absent(),
  });
  FlashcardRowsCompanion.insert({
    this.id = const Value.absent(),
    required int studySetId,
    required String front,
    required String back,
    this.source = const Value.absent(),
  }) : studySetId = Value(studySetId),
       front = Value(front),
       back = Value(back);
  static Insertable<FlashcardRow> custom({
    Expression<int>? id,
    Expression<int>? studySetId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studySetId != null) 'study_set_id': studySetId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (source != null) 'source': source,
    });
  }

  FlashcardRowsCompanion copyWith({
    Value<int>? id,
    Value<int>? studySetId,
    Value<String>? front,
    Value<String>? back,
    Value<String>? source,
  }) {
    return FlashcardRowsCompanion(
      id: id ?? this.id,
      studySetId: studySetId ?? this.studySetId,
      front: front ?? this.front,
      back: back ?? this.back,
      source: source ?? this.source,
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
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardRowsCompanion(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('source: $source')
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

class $ReadersTable extends Readers with TableInfo<$ReadersTable, Reader> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _placedMeta = const VerificationMeta('placed');
  @override
  late final GeneratedColumn<bool> placed = GeneratedColumn<bool>(
    'placed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("placed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  List<GeneratedColumn> get $columns => [id, name, level, placed, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'readers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reader> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('placed')) {
      context.handle(
        _placedMeta,
        placed.isAcceptableOrUnknown(data['placed']!, _placedMeta),
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
  Reader map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reader(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      placed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}placed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReadersTable createAlias(String alias) {
    return $ReadersTable(attachedDatabase, alias);
  }
}

class Reader extends DataClass implements Insertable<Reader> {
  final int id;
  final String name;
  final int level;
  final bool placed;
  final DateTime createdAt;
  const Reader({
    required this.id,
    required this.name,
    required this.level,
    required this.placed,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['level'] = Variable<int>(level);
    map['placed'] = Variable<bool>(placed);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReadersCompanion toCompanion(bool nullToAbsent) {
    return ReadersCompanion(
      id: Value(id),
      name: Value(name),
      level: Value(level),
      placed: Value(placed),
      createdAt: Value(createdAt),
    );
  }

  factory Reader.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reader(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      level: serializer.fromJson<int>(json['level']),
      placed: serializer.fromJson<bool>(json['placed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'level': serializer.toJson<int>(level),
      'placed': serializer.toJson<bool>(placed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Reader copyWith({
    int? id,
    String? name,
    int? level,
    bool? placed,
    DateTime? createdAt,
  }) => Reader(
    id: id ?? this.id,
    name: name ?? this.name,
    level: level ?? this.level,
    placed: placed ?? this.placed,
    createdAt: createdAt ?? this.createdAt,
  );
  Reader copyWithCompanion(ReadersCompanion data) {
    return Reader(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      level: data.level.present ? data.level.value : this.level,
      placed: data.placed.present ? data.placed.value : this.placed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reader(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('placed: $placed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, level, placed, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reader &&
          other.id == this.id &&
          other.name == this.name &&
          other.level == this.level &&
          other.placed == this.placed &&
          other.createdAt == this.createdAt);
}

class ReadersCompanion extends UpdateCompanion<Reader> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> level;
  final Value<bool> placed;
  final Value<DateTime> createdAt;
  const ReadersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.level = const Value.absent(),
    this.placed = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReadersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.level = const Value.absent(),
    this.placed = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Reader> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? level,
    Expression<bool>? placed,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (level != null) 'level': level,
      if (placed != null) 'placed': placed,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReadersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? level,
    Value<bool>? placed,
    Value<DateTime>? createdAt,
  }) {
    return ReadersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      placed: placed ?? this.placed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (placed.present) {
      map['placed'] = Variable<bool>(placed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('placed: $placed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $StoriesTable extends Stories with TableInfo<$StoriesTable, StoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _parasMeta = const VerificationMeta('paras');
  @override
  late final GeneratedColumn<String> paras = GeneratedColumn<String>(
    'paras',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionsMeta = const VerificationMeta(
    'questions',
  );
  @override
  late final GeneratedColumn<String> questions = GeneratedColumn<String>(
    'questions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksMeta = const VerificationMeta('checks');
  @override
  late final GeneratedColumn<String> checks = GeneratedColumn<String>(
    'checks',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _pipelineMeta = const VerificationMeta(
    'pipeline',
  );
  @override
  late final GeneratedColumn<int> pipeline = GeneratedColumn<int>(
    'pipeline',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ai'),
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
    level,
    topic,
    title,
    paras,
    questions,
    checks,
    pipeline,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stories';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('paras')) {
      context.handle(
        _parasMeta,
        paras.isAcceptableOrUnknown(data['paras']!, _parasMeta),
      );
    } else if (isInserting) {
      context.missing(_parasMeta);
    }
    if (data.containsKey('questions')) {
      context.handle(
        _questionsMeta,
        questions.isAcceptableOrUnknown(data['questions']!, _questionsMeta),
      );
    } else if (isInserting) {
      context.missing(_questionsMeta);
    }
    if (data.containsKey('checks')) {
      context.handle(
        _checksMeta,
        checks.isAcceptableOrUnknown(data['checks']!, _checksMeta),
      );
    }
    if (data.containsKey('pipeline')) {
      context.handle(
        _pipelineMeta,
        pipeline.isAcceptableOrUnknown(data['pipeline']!, _pipelineMeta),
      );
    } else if (isInserting) {
      context.missing(_pipelineMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
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
  StoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      paras: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paras'],
      )!,
      questions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}questions'],
      )!,
      checks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checks'],
      )!,
      pipeline: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pipeline'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StoriesTable createAlias(String alias) {
    return $StoriesTable(attachedDatabase, alias);
  }
}

class StoryRow extends DataClass implements Insertable<StoryRow> {
  final int id;
  final int level;
  final String topic;
  final String title;
  final String paras;
  final String questions;
  final String checks;
  final int pipeline;
  final String source;
  final DateTime createdAt;
  const StoryRow({
    required this.id,
    required this.level,
    required this.topic,
    required this.title,
    required this.paras,
    required this.questions,
    required this.checks,
    required this.pipeline,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['level'] = Variable<int>(level);
    map['topic'] = Variable<String>(topic);
    map['title'] = Variable<String>(title);
    map['paras'] = Variable<String>(paras);
    map['questions'] = Variable<String>(questions);
    map['checks'] = Variable<String>(checks);
    map['pipeline'] = Variable<int>(pipeline);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StoriesCompanion toCompanion(bool nullToAbsent) {
    return StoriesCompanion(
      id: Value(id),
      level: Value(level),
      topic: Value(topic),
      title: Value(title),
      paras: Value(paras),
      questions: Value(questions),
      checks: Value(checks),
      pipeline: Value(pipeline),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory StoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoryRow(
      id: serializer.fromJson<int>(json['id']),
      level: serializer.fromJson<int>(json['level']),
      topic: serializer.fromJson<String>(json['topic']),
      title: serializer.fromJson<String>(json['title']),
      paras: serializer.fromJson<String>(json['paras']),
      questions: serializer.fromJson<String>(json['questions']),
      checks: serializer.fromJson<String>(json['checks']),
      pipeline: serializer.fromJson<int>(json['pipeline']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'level': serializer.toJson<int>(level),
      'topic': serializer.toJson<String>(topic),
      'title': serializer.toJson<String>(title),
      'paras': serializer.toJson<String>(paras),
      'questions': serializer.toJson<String>(questions),
      'checks': serializer.toJson<String>(checks),
      'pipeline': serializer.toJson<int>(pipeline),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StoryRow copyWith({
    int? id,
    int? level,
    String? topic,
    String? title,
    String? paras,
    String? questions,
    String? checks,
    int? pipeline,
    String? source,
    DateTime? createdAt,
  }) => StoryRow(
    id: id ?? this.id,
    level: level ?? this.level,
    topic: topic ?? this.topic,
    title: title ?? this.title,
    paras: paras ?? this.paras,
    questions: questions ?? this.questions,
    checks: checks ?? this.checks,
    pipeline: pipeline ?? this.pipeline,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  StoryRow copyWithCompanion(StoriesCompanion data) {
    return StoryRow(
      id: data.id.present ? data.id.value : this.id,
      level: data.level.present ? data.level.value : this.level,
      topic: data.topic.present ? data.topic.value : this.topic,
      title: data.title.present ? data.title.value : this.title,
      paras: data.paras.present ? data.paras.value : this.paras,
      questions: data.questions.present ? data.questions.value : this.questions,
      checks: data.checks.present ? data.checks.value : this.checks,
      pipeline: data.pipeline.present ? data.pipeline.value : this.pipeline,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoryRow(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('topic: $topic, ')
          ..write('title: $title, ')
          ..write('paras: $paras, ')
          ..write('questions: $questions, ')
          ..write('checks: $checks, ')
          ..write('pipeline: $pipeline, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    level,
    topic,
    title,
    paras,
    questions,
    checks,
    pipeline,
    source,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoryRow &&
          other.id == this.id &&
          other.level == this.level &&
          other.topic == this.topic &&
          other.title == this.title &&
          other.paras == this.paras &&
          other.questions == this.questions &&
          other.checks == this.checks &&
          other.pipeline == this.pipeline &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class StoriesCompanion extends UpdateCompanion<StoryRow> {
  final Value<int> id;
  final Value<int> level;
  final Value<String> topic;
  final Value<String> title;
  final Value<String> paras;
  final Value<String> questions;
  final Value<String> checks;
  final Value<int> pipeline;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const StoriesCompanion({
    this.id = const Value.absent(),
    this.level = const Value.absent(),
    this.topic = const Value.absent(),
    this.title = const Value.absent(),
    this.paras = const Value.absent(),
    this.questions = const Value.absent(),
    this.checks = const Value.absent(),
    this.pipeline = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  StoriesCompanion.insert({
    this.id = const Value.absent(),
    required int level,
    required String topic,
    required String title,
    required String paras,
    required String questions,
    this.checks = const Value.absent(),
    required int pipeline,
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : level = Value(level),
       topic = Value(topic),
       title = Value(title),
       paras = Value(paras),
       questions = Value(questions),
       pipeline = Value(pipeline);
  static Insertable<StoryRow> custom({
    Expression<int>? id,
    Expression<int>? level,
    Expression<String>? topic,
    Expression<String>? title,
    Expression<String>? paras,
    Expression<String>? questions,
    Expression<String>? checks,
    Expression<int>? pipeline,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (level != null) 'level': level,
      if (topic != null) 'topic': topic,
      if (title != null) 'title': title,
      if (paras != null) 'paras': paras,
      if (questions != null) 'questions': questions,
      if (checks != null) 'checks': checks,
      if (pipeline != null) 'pipeline': pipeline,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  StoriesCompanion copyWith({
    Value<int>? id,
    Value<int>? level,
    Value<String>? topic,
    Value<String>? title,
    Value<String>? paras,
    Value<String>? questions,
    Value<String>? checks,
    Value<int>? pipeline,
    Value<String>? source,
    Value<DateTime>? createdAt,
  }) {
    return StoriesCompanion(
      id: id ?? this.id,
      level: level ?? this.level,
      topic: topic ?? this.topic,
      title: title ?? this.title,
      paras: paras ?? this.paras,
      questions: questions ?? this.questions,
      checks: checks ?? this.checks,
      pipeline: pipeline ?? this.pipeline,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (paras.present) {
      map['paras'] = Variable<String>(paras.value);
    }
    if (questions.present) {
      map['questions'] = Variable<String>(questions.value);
    }
    if (checks.present) {
      map['checks'] = Variable<String>(checks.value);
    }
    if (pipeline.present) {
      map['pipeline'] = Variable<int>(pipeline.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoriesCompanion(')
          ..write('id: $id, ')
          ..write('level: $level, ')
          ..write('topic: $topic, ')
          ..write('title: $title, ')
          ..write('paras: $paras, ')
          ..write('questions: $questions, ')
          ..write('checks: $checks, ')
          ..write('pipeline: $pipeline, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReadingAttemptsTable extends ReadingAttempts
    with TableInfo<$ReadingAttemptsTable, ReadingAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingAttemptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _readerIdMeta = const VerificationMeta(
    'readerId',
  );
  @override
  late final GeneratedColumn<int> readerId = GeneratedColumn<int>(
    'reader_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES readers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _storyIdMeta = const VerificationMeta(
    'storyId',
  );
  @override
  late final GeneratedColumn<int> storyId = GeneratedColumn<int>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stories (id)',
    ),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
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
  static const VerificationMeta _movedMeta = const VerificationMeta('moved');
  @override
  late final GeneratedColumn<int> moved = GeneratedColumn<int>(
    'moved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skillsMeta = const VerificationMeta('skills');
  @override
  late final GeneratedColumn<String> skills = GeneratedColumn<String>(
    'skills',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _wpmMeta = const VerificationMeta('wpm');
  @override
  late final GeneratedColumn<int> wpm = GeneratedColumn<int>(
    'wpm',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
    readerId,
    storyId,
    level,
    correct,
    total,
    moved,
    skills,
    wpm,
    takenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reader_id')) {
      context.handle(
        _readerIdMeta,
        readerId.isAcceptableOrUnknown(data['reader_id']!, _readerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_readerIdMeta);
    }
    if (data.containsKey('story_id')) {
      context.handle(
        _storyIdMeta,
        storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('moved')) {
      context.handle(
        _movedMeta,
        moved.isAcceptableOrUnknown(data['moved']!, _movedMeta),
      );
    }
    if (data.containsKey('skills')) {
      context.handle(
        _skillsMeta,
        skills.isAcceptableOrUnknown(data['skills']!, _skillsMeta),
      );
    }
    if (data.containsKey('wpm')) {
      context.handle(
        _wpmMeta,
        wpm.isAcceptableOrUnknown(data['wpm']!, _wpmMeta),
      );
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {readerId, storyId},
  ];
  @override
  ReadingAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      readerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reader_id'],
      )!,
      storyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}story_id'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      moved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moved'],
      )!,
      skills: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skills'],
      )!,
      wpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wpm'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
    );
  }

  @override
  $ReadingAttemptsTable createAlias(String alias) {
    return $ReadingAttemptsTable(attachedDatabase, alias);
  }
}

class ReadingAttempt extends DataClass implements Insertable<ReadingAttempt> {
  final int id;
  final int readerId;
  final int storyId;
  final int level;
  final int correct;
  final int total;
  final int moved;
  final String skills;
  final int? wpm;
  final DateTime takenAt;
  const ReadingAttempt({
    required this.id,
    required this.readerId,
    required this.storyId,
    required this.level,
    required this.correct,
    required this.total,
    required this.moved,
    required this.skills,
    this.wpm,
    required this.takenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reader_id'] = Variable<int>(readerId);
    map['story_id'] = Variable<int>(storyId);
    map['level'] = Variable<int>(level);
    map['correct'] = Variable<int>(correct);
    map['total'] = Variable<int>(total);
    map['moved'] = Variable<int>(moved);
    map['skills'] = Variable<String>(skills);
    if (!nullToAbsent || wpm != null) {
      map['wpm'] = Variable<int>(wpm);
    }
    map['taken_at'] = Variable<DateTime>(takenAt);
    return map;
  }

  ReadingAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ReadingAttemptsCompanion(
      id: Value(id),
      readerId: Value(readerId),
      storyId: Value(storyId),
      level: Value(level),
      correct: Value(correct),
      total: Value(total),
      moved: Value(moved),
      skills: Value(skills),
      wpm: wpm == null && nullToAbsent ? const Value.absent() : Value(wpm),
      takenAt: Value(takenAt),
    );
  }

  factory ReadingAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingAttempt(
      id: serializer.fromJson<int>(json['id']),
      readerId: serializer.fromJson<int>(json['readerId']),
      storyId: serializer.fromJson<int>(json['storyId']),
      level: serializer.fromJson<int>(json['level']),
      correct: serializer.fromJson<int>(json['correct']),
      total: serializer.fromJson<int>(json['total']),
      moved: serializer.fromJson<int>(json['moved']),
      skills: serializer.fromJson<String>(json['skills']),
      wpm: serializer.fromJson<int?>(json['wpm']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'readerId': serializer.toJson<int>(readerId),
      'storyId': serializer.toJson<int>(storyId),
      'level': serializer.toJson<int>(level),
      'correct': serializer.toJson<int>(correct),
      'total': serializer.toJson<int>(total),
      'moved': serializer.toJson<int>(moved),
      'skills': serializer.toJson<String>(skills),
      'wpm': serializer.toJson<int?>(wpm),
      'takenAt': serializer.toJson<DateTime>(takenAt),
    };
  }

  ReadingAttempt copyWith({
    int? id,
    int? readerId,
    int? storyId,
    int? level,
    int? correct,
    int? total,
    int? moved,
    String? skills,
    Value<int?> wpm = const Value.absent(),
    DateTime? takenAt,
  }) => ReadingAttempt(
    id: id ?? this.id,
    readerId: readerId ?? this.readerId,
    storyId: storyId ?? this.storyId,
    level: level ?? this.level,
    correct: correct ?? this.correct,
    total: total ?? this.total,
    moved: moved ?? this.moved,
    skills: skills ?? this.skills,
    wpm: wpm.present ? wpm.value : this.wpm,
    takenAt: takenAt ?? this.takenAt,
  );
  ReadingAttempt copyWithCompanion(ReadingAttemptsCompanion data) {
    return ReadingAttempt(
      id: data.id.present ? data.id.value : this.id,
      readerId: data.readerId.present ? data.readerId.value : this.readerId,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      level: data.level.present ? data.level.value : this.level,
      correct: data.correct.present ? data.correct.value : this.correct,
      total: data.total.present ? data.total.value : this.total,
      moved: data.moved.present ? data.moved.value : this.moved,
      skills: data.skills.present ? data.skills.value : this.skills,
      wpm: data.wpm.present ? data.wpm.value : this.wpm,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingAttempt(')
          ..write('id: $id, ')
          ..write('readerId: $readerId, ')
          ..write('storyId: $storyId, ')
          ..write('level: $level, ')
          ..write('correct: $correct, ')
          ..write('total: $total, ')
          ..write('moved: $moved, ')
          ..write('skills: $skills, ')
          ..write('wpm: $wpm, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    readerId,
    storyId,
    level,
    correct,
    total,
    moved,
    skills,
    wpm,
    takenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingAttempt &&
          other.id == this.id &&
          other.readerId == this.readerId &&
          other.storyId == this.storyId &&
          other.level == this.level &&
          other.correct == this.correct &&
          other.total == this.total &&
          other.moved == this.moved &&
          other.skills == this.skills &&
          other.wpm == this.wpm &&
          other.takenAt == this.takenAt);
}

class ReadingAttemptsCompanion extends UpdateCompanion<ReadingAttempt> {
  final Value<int> id;
  final Value<int> readerId;
  final Value<int> storyId;
  final Value<int> level;
  final Value<int> correct;
  final Value<int> total;
  final Value<int> moved;
  final Value<String> skills;
  final Value<int?> wpm;
  final Value<DateTime> takenAt;
  const ReadingAttemptsCompanion({
    this.id = const Value.absent(),
    this.readerId = const Value.absent(),
    this.storyId = const Value.absent(),
    this.level = const Value.absent(),
    this.correct = const Value.absent(),
    this.total = const Value.absent(),
    this.moved = const Value.absent(),
    this.skills = const Value.absent(),
    this.wpm = const Value.absent(),
    this.takenAt = const Value.absent(),
  });
  ReadingAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int readerId,
    required int storyId,
    required int level,
    required int correct,
    required int total,
    this.moved = const Value.absent(),
    this.skills = const Value.absent(),
    this.wpm = const Value.absent(),
    this.takenAt = const Value.absent(),
  }) : readerId = Value(readerId),
       storyId = Value(storyId),
       level = Value(level),
       correct = Value(correct),
       total = Value(total);
  static Insertable<ReadingAttempt> custom({
    Expression<int>? id,
    Expression<int>? readerId,
    Expression<int>? storyId,
    Expression<int>? level,
    Expression<int>? correct,
    Expression<int>? total,
    Expression<int>? moved,
    Expression<String>? skills,
    Expression<int>? wpm,
    Expression<DateTime>? takenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (readerId != null) 'reader_id': readerId,
      if (storyId != null) 'story_id': storyId,
      if (level != null) 'level': level,
      if (correct != null) 'correct': correct,
      if (total != null) 'total': total,
      if (moved != null) 'moved': moved,
      if (skills != null) 'skills': skills,
      if (wpm != null) 'wpm': wpm,
      if (takenAt != null) 'taken_at': takenAt,
    });
  }

  ReadingAttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? readerId,
    Value<int>? storyId,
    Value<int>? level,
    Value<int>? correct,
    Value<int>? total,
    Value<int>? moved,
    Value<String>? skills,
    Value<int?>? wpm,
    Value<DateTime>? takenAt,
  }) {
    return ReadingAttemptsCompanion(
      id: id ?? this.id,
      readerId: readerId ?? this.readerId,
      storyId: storyId ?? this.storyId,
      level: level ?? this.level,
      correct: correct ?? this.correct,
      total: total ?? this.total,
      moved: moved ?? this.moved,
      skills: skills ?? this.skills,
      wpm: wpm ?? this.wpm,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (readerId.present) {
      map['reader_id'] = Variable<int>(readerId.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<int>(storyId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (moved.present) {
      map['moved'] = Variable<int>(moved.value);
    }
    if (skills.present) {
      map['skills'] = Variable<String>(skills.value);
    }
    if (wpm.present) {
      map['wpm'] = Variable<int>(wpm.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('readerId: $readerId, ')
          ..write('storyId: $storyId, ')
          ..write('level: $level, ')
          ..write('correct: $correct, ')
          ..write('total: $total, ')
          ..write('moved: $moved, ')
          ..write('skills: $skills, ')
          ..write('wpm: $wpm, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }
}

class $SavedWordsTable extends SavedWords
    with TableInfo<$SavedWordsTable, SavedWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedWordsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _readerIdMeta = const VerificationMeta(
    'readerId',
  );
  @override
  late final GeneratedColumn<int> readerId = GeneratedColumn<int>(
    'reader_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES readers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _synonymMeta = const VerificationMeta(
    'synonym',
  );
  @override
  late final GeneratedColumn<String> synonym = GeneratedColumn<String>(
    'synonym',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sentenceMeta = const VerificationMeta(
    'sentence',
  );
  @override
  late final GeneratedColumn<String> sentence = GeneratedColumn<String>(
    'sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timesMeta = const VerificationMeta('times');
  @override
  late final GeneratedColumn<int> times = GeneratedColumn<int>(
    'times',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _knownMeta = const VerificationMeta('known');
  @override
  late final GeneratedColumn<int> known = GeneratedColumn<int>(
    'known',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    readerId,
    word,
    meaning,
    synonym,
    sentence,
    times,
    known,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reader_id')) {
      context.handle(
        _readerIdMeta,
        readerId.isAcceptableOrUnknown(data['reader_id']!, _readerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_readerIdMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('synonym')) {
      context.handle(
        _synonymMeta,
        synonym.isAcceptableOrUnknown(data['synonym']!, _synonymMeta),
      );
    }
    if (data.containsKey('sentence')) {
      context.handle(
        _sentenceMeta,
        sentence.isAcceptableOrUnknown(data['sentence']!, _sentenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sentenceMeta);
    }
    if (data.containsKey('times')) {
      context.handle(
        _timesMeta,
        times.isAcceptableOrUnknown(data['times']!, _timesMeta),
      );
    }
    if (data.containsKey('known')) {
      context.handle(
        _knownMeta,
        known.isAcceptableOrUnknown(data['known']!, _knownMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {readerId, word},
  ];
  @override
  SavedWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedWord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      readerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reader_id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      synonym: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}synonym'],
      ),
      sentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentence'],
      )!,
      times: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times'],
      )!,
      known: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}known'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SavedWordsTable createAlias(String alias) {
    return $SavedWordsTable(attachedDatabase, alias);
  }
}

class SavedWord extends DataClass implements Insertable<SavedWord> {
  final int id;
  final int readerId;
  final String word;
  final String meaning;
  final String? synonym;
  final String sentence;
  final int times;
  final int known;
  final DateTime savedAt;
  const SavedWord({
    required this.id,
    required this.readerId,
    required this.word,
    required this.meaning,
    this.synonym,
    required this.sentence,
    required this.times,
    required this.known,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reader_id'] = Variable<int>(readerId);
    map['word'] = Variable<String>(word);
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || synonym != null) {
      map['synonym'] = Variable<String>(synonym);
    }
    map['sentence'] = Variable<String>(sentence);
    map['times'] = Variable<int>(times);
    map['known'] = Variable<int>(known);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedWordsCompanion toCompanion(bool nullToAbsent) {
    return SavedWordsCompanion(
      id: Value(id),
      readerId: Value(readerId),
      word: Value(word),
      meaning: Value(meaning),
      synonym: synonym == null && nullToAbsent
          ? const Value.absent()
          : Value(synonym),
      sentence: Value(sentence),
      times: Value(times),
      known: Value(known),
      savedAt: Value(savedAt),
    );
  }

  factory SavedWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedWord(
      id: serializer.fromJson<int>(json['id']),
      readerId: serializer.fromJson<int>(json['readerId']),
      word: serializer.fromJson<String>(json['word']),
      meaning: serializer.fromJson<String>(json['meaning']),
      synonym: serializer.fromJson<String?>(json['synonym']),
      sentence: serializer.fromJson<String>(json['sentence']),
      times: serializer.fromJson<int>(json['times']),
      known: serializer.fromJson<int>(json['known']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'readerId': serializer.toJson<int>(readerId),
      'word': serializer.toJson<String>(word),
      'meaning': serializer.toJson<String>(meaning),
      'synonym': serializer.toJson<String?>(synonym),
      'sentence': serializer.toJson<String>(sentence),
      'times': serializer.toJson<int>(times),
      'known': serializer.toJson<int>(known),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedWord copyWith({
    int? id,
    int? readerId,
    String? word,
    String? meaning,
    Value<String?> synonym = const Value.absent(),
    String? sentence,
    int? times,
    int? known,
    DateTime? savedAt,
  }) => SavedWord(
    id: id ?? this.id,
    readerId: readerId ?? this.readerId,
    word: word ?? this.word,
    meaning: meaning ?? this.meaning,
    synonym: synonym.present ? synonym.value : this.synonym,
    sentence: sentence ?? this.sentence,
    times: times ?? this.times,
    known: known ?? this.known,
    savedAt: savedAt ?? this.savedAt,
  );
  SavedWord copyWithCompanion(SavedWordsCompanion data) {
    return SavedWord(
      id: data.id.present ? data.id.value : this.id,
      readerId: data.readerId.present ? data.readerId.value : this.readerId,
      word: data.word.present ? data.word.value : this.word,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      synonym: data.synonym.present ? data.synonym.value : this.synonym,
      sentence: data.sentence.present ? data.sentence.value : this.sentence,
      times: data.times.present ? data.times.value : this.times,
      known: data.known.present ? data.known.value : this.known,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedWord(')
          ..write('id: $id, ')
          ..write('readerId: $readerId, ')
          ..write('word: $word, ')
          ..write('meaning: $meaning, ')
          ..write('synonym: $synonym, ')
          ..write('sentence: $sentence, ')
          ..write('times: $times, ')
          ..write('known: $known, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    readerId,
    word,
    meaning,
    synonym,
    sentence,
    times,
    known,
    savedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedWord &&
          other.id == this.id &&
          other.readerId == this.readerId &&
          other.word == this.word &&
          other.meaning == this.meaning &&
          other.synonym == this.synonym &&
          other.sentence == this.sentence &&
          other.times == this.times &&
          other.known == this.known &&
          other.savedAt == this.savedAt);
}

class SavedWordsCompanion extends UpdateCompanion<SavedWord> {
  final Value<int> id;
  final Value<int> readerId;
  final Value<String> word;
  final Value<String> meaning;
  final Value<String?> synonym;
  final Value<String> sentence;
  final Value<int> times;
  final Value<int> known;
  final Value<DateTime> savedAt;
  const SavedWordsCompanion({
    this.id = const Value.absent(),
    this.readerId = const Value.absent(),
    this.word = const Value.absent(),
    this.meaning = const Value.absent(),
    this.synonym = const Value.absent(),
    this.sentence = const Value.absent(),
    this.times = const Value.absent(),
    this.known = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  SavedWordsCompanion.insert({
    this.id = const Value.absent(),
    required int readerId,
    required String word,
    required String meaning,
    this.synonym = const Value.absent(),
    required String sentence,
    this.times = const Value.absent(),
    this.known = const Value.absent(),
    this.savedAt = const Value.absent(),
  }) : readerId = Value(readerId),
       word = Value(word),
       meaning = Value(meaning),
       sentence = Value(sentence);
  static Insertable<SavedWord> custom({
    Expression<int>? id,
    Expression<int>? readerId,
    Expression<String>? word,
    Expression<String>? meaning,
    Expression<String>? synonym,
    Expression<String>? sentence,
    Expression<int>? times,
    Expression<int>? known,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (readerId != null) 'reader_id': readerId,
      if (word != null) 'word': word,
      if (meaning != null) 'meaning': meaning,
      if (synonym != null) 'synonym': synonym,
      if (sentence != null) 'sentence': sentence,
      if (times != null) 'times': times,
      if (known != null) 'known': known,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  SavedWordsCompanion copyWith({
    Value<int>? id,
    Value<int>? readerId,
    Value<String>? word,
    Value<String>? meaning,
    Value<String?>? synonym,
    Value<String>? sentence,
    Value<int>? times,
    Value<int>? known,
    Value<DateTime>? savedAt,
  }) {
    return SavedWordsCompanion(
      id: id ?? this.id,
      readerId: readerId ?? this.readerId,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      synonym: synonym ?? this.synonym,
      sentence: sentence ?? this.sentence,
      times: times ?? this.times,
      known: known ?? this.known,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (readerId.present) {
      map['reader_id'] = Variable<int>(readerId.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (synonym.present) {
      map['synonym'] = Variable<String>(synonym.value);
    }
    if (sentence.present) {
      map['sentence'] = Variable<String>(sentence.value);
    }
    if (times.present) {
      map['times'] = Variable<int>(times.value);
    }
    if (known.present) {
      map['known'] = Variable<int>(known.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedWordsCompanion(')
          ..write('id: $id, ')
          ..write('readerId: $readerId, ')
          ..write('word: $word, ')
          ..write('meaning: $meaning, ')
          ..write('synonym: $synonym, ')
          ..write('sentence: $sentence, ')
          ..write('times: $times, ')
          ..write('known: $known, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

class $ReviewStatesTable extends ReviewStates
    with TableInfo<$ReviewStatesTable, ReviewState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewStatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _boxMeta = const VerificationMeta('box');
  @override
  late final GeneratedColumn<int> box = GeneratedColumn<int>(
    'box',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<DateTime> dueDay = GeneratedColumn<DateTime>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAtMeta = const VerificationMeta('lastAt');
  @override
  late final GeneratedColumn<DateTime> lastAt = GeneratedColumn<DateTime>(
    'last_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streakMeta = const VerificationMeta('streak');
  @override
  late final GeneratedColumn<int> streak = GeneratedColumn<int>(
    'streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    itemId,
    studySetId,
    box,
    dueDay,
    lastAt,
    streak,
    lapses,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
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
    if (data.containsKey('box')) {
      context.handle(
        _boxMeta,
        box.isAcceptableOrUnknown(data['box']!, _boxMeta),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('last_at')) {
      context.handle(
        _lastAtMeta,
        lastAt.isAcceptableOrUnknown(data['last_at']!, _lastAtMeta),
      );
    }
    if (data.containsKey('streak')) {
      context.handle(
        _streakMeta,
        streak.isAcceptableOrUnknown(data['streak']!, _streakMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {kind, itemId},
  ];
  @override
  ReviewState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewState(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      studySetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}study_set_id'],
      )!,
      box: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_day'],
      ),
      lastAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_at'],
      ),
      streak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
    );
  }

  @override
  $ReviewStatesTable createAlias(String alias) {
    return $ReviewStatesTable(attachedDatabase, alias);
  }
}

class ReviewState extends DataClass implements Insertable<ReviewState> {
  final int id;
  final String kind;
  final int itemId;
  final int studySetId;
  final int box;
  final DateTime? dueDay;
  final DateTime? lastAt;
  final int streak;
  final int lapses;
  const ReviewState({
    required this.id,
    required this.kind,
    required this.itemId,
    required this.studySetId,
    required this.box,
    this.dueDay,
    this.lastAt,
    required this.streak,
    required this.lapses,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['item_id'] = Variable<int>(itemId);
    map['study_set_id'] = Variable<int>(studySetId);
    map['box'] = Variable<int>(box);
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<DateTime>(dueDay);
    }
    if (!nullToAbsent || lastAt != null) {
      map['last_at'] = Variable<DateTime>(lastAt);
    }
    map['streak'] = Variable<int>(streak);
    map['lapses'] = Variable<int>(lapses);
    return map;
  }

  ReviewStatesCompanion toCompanion(bool nullToAbsent) {
    return ReviewStatesCompanion(
      id: Value(id),
      kind: Value(kind),
      itemId: Value(itemId),
      studySetId: Value(studySetId),
      box: Value(box),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      lastAt: lastAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAt),
      streak: Value(streak),
      lapses: Value(lapses),
    );
  }

  factory ReviewState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewState(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      itemId: serializer.fromJson<int>(json['itemId']),
      studySetId: serializer.fromJson<int>(json['studySetId']),
      box: serializer.fromJson<int>(json['box']),
      dueDay: serializer.fromJson<DateTime?>(json['dueDay']),
      lastAt: serializer.fromJson<DateTime?>(json['lastAt']),
      streak: serializer.fromJson<int>(json['streak']),
      lapses: serializer.fromJson<int>(json['lapses']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'itemId': serializer.toJson<int>(itemId),
      'studySetId': serializer.toJson<int>(studySetId),
      'box': serializer.toJson<int>(box),
      'dueDay': serializer.toJson<DateTime?>(dueDay),
      'lastAt': serializer.toJson<DateTime?>(lastAt),
      'streak': serializer.toJson<int>(streak),
      'lapses': serializer.toJson<int>(lapses),
    };
  }

  ReviewState copyWith({
    int? id,
    String? kind,
    int? itemId,
    int? studySetId,
    int? box,
    Value<DateTime?> dueDay = const Value.absent(),
    Value<DateTime?> lastAt = const Value.absent(),
    int? streak,
    int? lapses,
  }) => ReviewState(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    studySetId: studySetId ?? this.studySetId,
    box: box ?? this.box,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    lastAt: lastAt.present ? lastAt.value : this.lastAt,
    streak: streak ?? this.streak,
    lapses: lapses ?? this.lapses,
  );
  ReviewState copyWithCompanion(ReviewStatesCompanion data) {
    return ReviewState(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      studySetId: data.studySetId.present
          ? data.studySetId.value
          : this.studySetId,
      box: data.box.present ? data.box.value : this.box,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      lastAt: data.lastAt.present ? data.lastAt.value : this.lastAt,
      streak: data.streak.present ? data.streak.value : this.streak,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewState(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('studySetId: $studySetId, ')
          ..write('box: $box, ')
          ..write('dueDay: $dueDay, ')
          ..write('lastAt: $lastAt, ')
          ..write('streak: $streak, ')
          ..write('lapses: $lapses')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    itemId,
    studySetId,
    box,
    dueDay,
    lastAt,
    streak,
    lapses,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewState &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.studySetId == this.studySetId &&
          other.box == this.box &&
          other.dueDay == this.dueDay &&
          other.lastAt == this.lastAt &&
          other.streak == this.streak &&
          other.lapses == this.lapses);
}

class ReviewStatesCompanion extends UpdateCompanion<ReviewState> {
  final Value<int> id;
  final Value<String> kind;
  final Value<int> itemId;
  final Value<int> studySetId;
  final Value<int> box;
  final Value<DateTime?> dueDay;
  final Value<DateTime?> lastAt;
  final Value<int> streak;
  final Value<int> lapses;
  const ReviewStatesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.box = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.lastAt = const Value.absent(),
    this.streak = const Value.absent(),
    this.lapses = const Value.absent(),
  });
  ReviewStatesCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required int itemId,
    required int studySetId,
    this.box = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.lastAt = const Value.absent(),
    this.streak = const Value.absent(),
    this.lapses = const Value.absent(),
  }) : kind = Value(kind),
       itemId = Value(itemId),
       studySetId = Value(studySetId);
  static Insertable<ReviewState> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? itemId,
    Expression<int>? studySetId,
    Expression<int>? box,
    Expression<DateTime>? dueDay,
    Expression<DateTime>? lastAt,
    Expression<int>? streak,
    Expression<int>? lapses,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (studySetId != null) 'study_set_id': studySetId,
      if (box != null) 'box': box,
      if (dueDay != null) 'due_day': dueDay,
      if (lastAt != null) 'last_at': lastAt,
      if (streak != null) 'streak': streak,
      if (lapses != null) 'lapses': lapses,
    });
  }

  ReviewStatesCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<int>? itemId,
    Value<int>? studySetId,
    Value<int>? box,
    Value<DateTime?>? dueDay,
    Value<DateTime?>? lastAt,
    Value<int>? streak,
    Value<int>? lapses,
  }) {
    return ReviewStatesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      studySetId: studySetId ?? this.studySetId,
      box: box ?? this.box,
      dueDay: dueDay ?? this.dueDay,
      lastAt: lastAt ?? this.lastAt,
      streak: streak ?? this.streak,
      lapses: lapses ?? this.lapses,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (studySetId.present) {
      map['study_set_id'] = Variable<int>(studySetId.value);
    }
    if (box.present) {
      map['box'] = Variable<int>(box.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<DateTime>(dueDay.value);
    }
    if (lastAt.present) {
      map['last_at'] = Variable<DateTime>(lastAt.value);
    }
    if (streak.present) {
      map['streak'] = Variable<int>(streak.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewStatesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('studySetId: $studySetId, ')
          ..write('box: $box, ')
          ..write('dueDay: $dueDay, ')
          ..write('lastAt: $lastAt, ')
          ..write('streak: $streak, ')
          ..write('lapses: $lapses')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogTable extends ReviewLog
    with TableInfo<$ReviewLogTable, ReviewEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _chosenMeta = const VerificationMeta('chosen');
  @override
  late final GeneratedColumn<int> chosen = GeneratedColumn<int>(
    'chosen',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    itemId,
    studySetId,
    correct,
    chosen,
    mode,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
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
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('chosen')) {
      context.handle(
        _chosenMeta,
        chosen.isAcceptableOrUnknown(data['chosen']!, _chosenMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      studySetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}study_set_id'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      )!,
      chosen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chosen'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $ReviewLogTable createAlias(String alias) {
    return $ReviewLogTable(attachedDatabase, alias);
  }
}

class ReviewEntry extends DataClass implements Insertable<ReviewEntry> {
  final int id;
  final String kind;
  final int itemId;
  final int studySetId;
  final bool correct;
  final int? chosen;
  final String mode;
  final DateTime at;
  const ReviewEntry({
    required this.id,
    required this.kind,
    required this.itemId,
    required this.studySetId,
    required this.correct,
    this.chosen,
    required this.mode,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['item_id'] = Variable<int>(itemId);
    map['study_set_id'] = Variable<int>(studySetId);
    map['correct'] = Variable<bool>(correct);
    if (!nullToAbsent || chosen != null) {
      map['chosen'] = Variable<int>(chosen);
    }
    map['mode'] = Variable<String>(mode);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  ReviewLogCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogCompanion(
      id: Value(id),
      kind: Value(kind),
      itemId: Value(itemId),
      studySetId: Value(studySetId),
      correct: Value(correct),
      chosen: chosen == null && nullToAbsent
          ? const Value.absent()
          : Value(chosen),
      mode: Value(mode),
      at: Value(at),
    );
  }

  factory ReviewEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewEntry(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      itemId: serializer.fromJson<int>(json['itemId']),
      studySetId: serializer.fromJson<int>(json['studySetId']),
      correct: serializer.fromJson<bool>(json['correct']),
      chosen: serializer.fromJson<int?>(json['chosen']),
      mode: serializer.fromJson<String>(json['mode']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'itemId': serializer.toJson<int>(itemId),
      'studySetId': serializer.toJson<int>(studySetId),
      'correct': serializer.toJson<bool>(correct),
      'chosen': serializer.toJson<int?>(chosen),
      'mode': serializer.toJson<String>(mode),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  ReviewEntry copyWith({
    int? id,
    String? kind,
    int? itemId,
    int? studySetId,
    bool? correct,
    Value<int?> chosen = const Value.absent(),
    String? mode,
    DateTime? at,
  }) => ReviewEntry(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    itemId: itemId ?? this.itemId,
    studySetId: studySetId ?? this.studySetId,
    correct: correct ?? this.correct,
    chosen: chosen.present ? chosen.value : this.chosen,
    mode: mode ?? this.mode,
    at: at ?? this.at,
  );
  ReviewEntry copyWithCompanion(ReviewLogCompanion data) {
    return ReviewEntry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      studySetId: data.studySetId.present
          ? data.studySetId.value
          : this.studySetId,
      correct: data.correct.present ? data.correct.value : this.correct,
      chosen: data.chosen.present ? data.chosen.value : this.chosen,
      mode: data.mode.present ? data.mode.value : this.mode,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEntry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('studySetId: $studySetId, ')
          ..write('correct: $correct, ')
          ..write('chosen: $chosen, ')
          ..write('mode: $mode, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, kind, itemId, studySetId, correct, chosen, mode, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewEntry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.itemId == this.itemId &&
          other.studySetId == this.studySetId &&
          other.correct == this.correct &&
          other.chosen == this.chosen &&
          other.mode == this.mode &&
          other.at == this.at);
}

class ReviewLogCompanion extends UpdateCompanion<ReviewEntry> {
  final Value<int> id;
  final Value<String> kind;
  final Value<int> itemId;
  final Value<int> studySetId;
  final Value<bool> correct;
  final Value<int?> chosen;
  final Value<String> mode;
  final Value<DateTime> at;
  const ReviewLogCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.itemId = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.correct = const Value.absent(),
    this.chosen = const Value.absent(),
    this.mode = const Value.absent(),
    this.at = const Value.absent(),
  });
  ReviewLogCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required int itemId,
    required int studySetId,
    required bool correct,
    this.chosen = const Value.absent(),
    required String mode,
    this.at = const Value.absent(),
  }) : kind = Value(kind),
       itemId = Value(itemId),
       studySetId = Value(studySetId),
       correct = Value(correct),
       mode = Value(mode);
  static Insertable<ReviewEntry> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? itemId,
    Expression<int>? studySetId,
    Expression<bool>? correct,
    Expression<int>? chosen,
    Expression<String>? mode,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (itemId != null) 'item_id': itemId,
      if (studySetId != null) 'study_set_id': studySetId,
      if (correct != null) 'correct': correct,
      if (chosen != null) 'chosen': chosen,
      if (mode != null) 'mode': mode,
      if (at != null) 'at': at,
    });
  }

  ReviewLogCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<int>? itemId,
    Value<int>? studySetId,
    Value<bool>? correct,
    Value<int?>? chosen,
    Value<String>? mode,
    Value<DateTime>? at,
  }) {
    return ReviewLogCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      itemId: itemId ?? this.itemId,
      studySetId: studySetId ?? this.studySetId,
      correct: correct ?? this.correct,
      chosen: chosen ?? this.chosen,
      mode: mode ?? this.mode,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (studySetId.present) {
      map['study_set_id'] = Variable<int>(studySetId.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    if (chosen.present) {
      map['chosen'] = Variable<int>(chosen.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('itemId: $itemId, ')
          ..write('studySetId: $studySetId, ')
          ..write('correct: $correct, ')
          ..write('chosen: $chosen, ')
          ..write('mode: $mode, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $TeachBackAttemptsTable extends TeachBackAttempts
    with TableInfo<$TeachBackAttemptsTable, TeachBackAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeachBackAttemptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionIndexMeta = const VerificationMeta(
    'sectionIndex',
  );
  @override
  late final GeneratedColumn<int> sectionIndex = GeneratedColumn<int>(
    'section_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coveredMeta = const VerificationMeta(
    'covered',
  );
  @override
  late final GeneratedColumn<int> covered = GeneratedColumn<int>(
    'covered',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _partlyMeta = const VerificationMeta('partly');
  @override
  late final GeneratedColumn<int> partly = GeneratedColumn<int>(
    'partly',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _copiedMeta = const VerificationMeta('copied');
  @override
  late final GeneratedColumn<bool> copied = GeneratedColumn<bool>(
    'copied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("copied" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _flagCountMeta = const VerificationMeta(
    'flagCount',
  );
  @override
  late final GeneratedColumn<int> flagCount = GeneratedColumn<int>(
    'flag_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _checkedByMeta = const VerificationMeta(
    'checkedBy',
  );
  @override
  late final GeneratedColumn<String> checkedBy = GeneratedColumn<String>(
    'checked_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('words'),
  );
  static const VerificationMeta _overruledMeta = const VerificationMeta(
    'overruled',
  );
  @override
  late final GeneratedColumn<String> overruled = GeneratedColumn<String>(
    'overruled',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
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
    section,
    sectionIndex,
    answer,
    covered,
    partly,
    total,
    copied,
    flagCount,
    checkedBy,
    overruled,
    takenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teach_back_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TeachBackAttempt> instance, {
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
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('section_index')) {
      context.handle(
        _sectionIndexMeta,
        sectionIndex.isAcceptableOrUnknown(
          data['section_index']!,
          _sectionIndexMeta,
        ),
      );
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('covered')) {
      context.handle(
        _coveredMeta,
        covered.isAcceptableOrUnknown(data['covered']!, _coveredMeta),
      );
    }
    if (data.containsKey('partly')) {
      context.handle(
        _partlyMeta,
        partly.isAcceptableOrUnknown(data['partly']!, _partlyMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    if (data.containsKey('copied')) {
      context.handle(
        _copiedMeta,
        copied.isAcceptableOrUnknown(data['copied']!, _copiedMeta),
      );
    }
    if (data.containsKey('flag_count')) {
      context.handle(
        _flagCountMeta,
        flagCount.isAcceptableOrUnknown(data['flag_count']!, _flagCountMeta),
      );
    }
    if (data.containsKey('checked_by')) {
      context.handle(
        _checkedByMeta,
        checkedBy.isAcceptableOrUnknown(data['checked_by']!, _checkedByMeta),
      );
    }
    if (data.containsKey('overruled')) {
      context.handle(
        _overruledMeta,
        overruled.isAcceptableOrUnknown(data['overruled']!, _overruledMeta),
      );
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
  TeachBackAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TeachBackAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studySetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}study_set_id'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      )!,
      sectionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}section_index'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      covered: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}covered'],
      )!,
      partly: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}partly'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      copied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}copied'],
      )!,
      flagCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}flag_count'],
      )!,
      checkedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checked_by'],
      )!,
      overruled: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overruled'],
      )!,
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
    );
  }

  @override
  $TeachBackAttemptsTable createAlias(String alias) {
    return $TeachBackAttemptsTable(attachedDatabase, alias);
  }
}

class TeachBackAttempt extends DataClass
    implements Insertable<TeachBackAttempt> {
  final int id;
  final int studySetId;
  final String section;
  final int sectionIndex;
  final String answer;
  final int covered;
  final int partly;
  final int total;
  final bool copied;
  final int flagCount;

  /// 'model' if the AI model judged it, 'words' if only a comparison of words did.
  final String checkedBy;

  /// JSON list of the positions of ideas the student said they covered after all.
  final String overruled;
  final DateTime takenAt;
  const TeachBackAttempt({
    required this.id,
    required this.studySetId,
    required this.section,
    required this.sectionIndex,
    required this.answer,
    required this.covered,
    required this.partly,
    required this.total,
    required this.copied,
    required this.flagCount,
    required this.checkedBy,
    required this.overruled,
    required this.takenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['study_set_id'] = Variable<int>(studySetId);
    map['section'] = Variable<String>(section);
    map['section_index'] = Variable<int>(sectionIndex);
    map['answer'] = Variable<String>(answer);
    map['covered'] = Variable<int>(covered);
    map['partly'] = Variable<int>(partly);
    map['total'] = Variable<int>(total);
    map['copied'] = Variable<bool>(copied);
    map['flag_count'] = Variable<int>(flagCount);
    map['checked_by'] = Variable<String>(checkedBy);
    map['overruled'] = Variable<String>(overruled);
    map['taken_at'] = Variable<DateTime>(takenAt);
    return map;
  }

  TeachBackAttemptsCompanion toCompanion(bool nullToAbsent) {
    return TeachBackAttemptsCompanion(
      id: Value(id),
      studySetId: Value(studySetId),
      section: Value(section),
      sectionIndex: Value(sectionIndex),
      answer: Value(answer),
      covered: Value(covered),
      partly: Value(partly),
      total: Value(total),
      copied: Value(copied),
      flagCount: Value(flagCount),
      checkedBy: Value(checkedBy),
      overruled: Value(overruled),
      takenAt: Value(takenAt),
    );
  }

  factory TeachBackAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TeachBackAttempt(
      id: serializer.fromJson<int>(json['id']),
      studySetId: serializer.fromJson<int>(json['studySetId']),
      section: serializer.fromJson<String>(json['section']),
      sectionIndex: serializer.fromJson<int>(json['sectionIndex']),
      answer: serializer.fromJson<String>(json['answer']),
      covered: serializer.fromJson<int>(json['covered']),
      partly: serializer.fromJson<int>(json['partly']),
      total: serializer.fromJson<int>(json['total']),
      copied: serializer.fromJson<bool>(json['copied']),
      flagCount: serializer.fromJson<int>(json['flagCount']),
      checkedBy: serializer.fromJson<String>(json['checkedBy']),
      overruled: serializer.fromJson<String>(json['overruled']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studySetId': serializer.toJson<int>(studySetId),
      'section': serializer.toJson<String>(section),
      'sectionIndex': serializer.toJson<int>(sectionIndex),
      'answer': serializer.toJson<String>(answer),
      'covered': serializer.toJson<int>(covered),
      'partly': serializer.toJson<int>(partly),
      'total': serializer.toJson<int>(total),
      'copied': serializer.toJson<bool>(copied),
      'flagCount': serializer.toJson<int>(flagCount),
      'checkedBy': serializer.toJson<String>(checkedBy),
      'overruled': serializer.toJson<String>(overruled),
      'takenAt': serializer.toJson<DateTime>(takenAt),
    };
  }

  TeachBackAttempt copyWith({
    int? id,
    int? studySetId,
    String? section,
    int? sectionIndex,
    String? answer,
    int? covered,
    int? partly,
    int? total,
    bool? copied,
    int? flagCount,
    String? checkedBy,
    String? overruled,
    DateTime? takenAt,
  }) => TeachBackAttempt(
    id: id ?? this.id,
    studySetId: studySetId ?? this.studySetId,
    section: section ?? this.section,
    sectionIndex: sectionIndex ?? this.sectionIndex,
    answer: answer ?? this.answer,
    covered: covered ?? this.covered,
    partly: partly ?? this.partly,
    total: total ?? this.total,
    copied: copied ?? this.copied,
    flagCount: flagCount ?? this.flagCount,
    checkedBy: checkedBy ?? this.checkedBy,
    overruled: overruled ?? this.overruled,
    takenAt: takenAt ?? this.takenAt,
  );
  TeachBackAttempt copyWithCompanion(TeachBackAttemptsCompanion data) {
    return TeachBackAttempt(
      id: data.id.present ? data.id.value : this.id,
      studySetId: data.studySetId.present
          ? data.studySetId.value
          : this.studySetId,
      section: data.section.present ? data.section.value : this.section,
      sectionIndex: data.sectionIndex.present
          ? data.sectionIndex.value
          : this.sectionIndex,
      answer: data.answer.present ? data.answer.value : this.answer,
      covered: data.covered.present ? data.covered.value : this.covered,
      partly: data.partly.present ? data.partly.value : this.partly,
      total: data.total.present ? data.total.value : this.total,
      copied: data.copied.present ? data.copied.value : this.copied,
      flagCount: data.flagCount.present ? data.flagCount.value : this.flagCount,
      checkedBy: data.checkedBy.present ? data.checkedBy.value : this.checkedBy,
      overruled: data.overruled.present ? data.overruled.value : this.overruled,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TeachBackAttempt(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('section: $section, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('answer: $answer, ')
          ..write('covered: $covered, ')
          ..write('partly: $partly, ')
          ..write('total: $total, ')
          ..write('copied: $copied, ')
          ..write('flagCount: $flagCount, ')
          ..write('checkedBy: $checkedBy, ')
          ..write('overruled: $overruled, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    studySetId,
    section,
    sectionIndex,
    answer,
    covered,
    partly,
    total,
    copied,
    flagCount,
    checkedBy,
    overruled,
    takenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TeachBackAttempt &&
          other.id == this.id &&
          other.studySetId == this.studySetId &&
          other.section == this.section &&
          other.sectionIndex == this.sectionIndex &&
          other.answer == this.answer &&
          other.covered == this.covered &&
          other.partly == this.partly &&
          other.total == this.total &&
          other.copied == this.copied &&
          other.flagCount == this.flagCount &&
          other.checkedBy == this.checkedBy &&
          other.overruled == this.overruled &&
          other.takenAt == this.takenAt);
}

class TeachBackAttemptsCompanion extends UpdateCompanion<TeachBackAttempt> {
  final Value<int> id;
  final Value<int> studySetId;
  final Value<String> section;
  final Value<int> sectionIndex;
  final Value<String> answer;
  final Value<int> covered;
  final Value<int> partly;
  final Value<int> total;
  final Value<bool> copied;
  final Value<int> flagCount;
  final Value<String> checkedBy;
  final Value<String> overruled;
  final Value<DateTime> takenAt;
  const TeachBackAttemptsCompanion({
    this.id = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.section = const Value.absent(),
    this.sectionIndex = const Value.absent(),
    this.answer = const Value.absent(),
    this.covered = const Value.absent(),
    this.partly = const Value.absent(),
    this.total = const Value.absent(),
    this.copied = const Value.absent(),
    this.flagCount = const Value.absent(),
    this.checkedBy = const Value.absent(),
    this.overruled = const Value.absent(),
    this.takenAt = const Value.absent(),
  });
  TeachBackAttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int studySetId,
    required String section,
    this.sectionIndex = const Value.absent(),
    required String answer,
    this.covered = const Value.absent(),
    this.partly = const Value.absent(),
    this.total = const Value.absent(),
    this.copied = const Value.absent(),
    this.flagCount = const Value.absent(),
    this.checkedBy = const Value.absent(),
    this.overruled = const Value.absent(),
    this.takenAt = const Value.absent(),
  }) : studySetId = Value(studySetId),
       section = Value(section),
       answer = Value(answer);
  static Insertable<TeachBackAttempt> custom({
    Expression<int>? id,
    Expression<int>? studySetId,
    Expression<String>? section,
    Expression<int>? sectionIndex,
    Expression<String>? answer,
    Expression<int>? covered,
    Expression<int>? partly,
    Expression<int>? total,
    Expression<bool>? copied,
    Expression<int>? flagCount,
    Expression<String>? checkedBy,
    Expression<String>? overruled,
    Expression<DateTime>? takenAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studySetId != null) 'study_set_id': studySetId,
      if (section != null) 'section': section,
      if (sectionIndex != null) 'section_index': sectionIndex,
      if (answer != null) 'answer': answer,
      if (covered != null) 'covered': covered,
      if (partly != null) 'partly': partly,
      if (total != null) 'total': total,
      if (copied != null) 'copied': copied,
      if (flagCount != null) 'flag_count': flagCount,
      if (checkedBy != null) 'checked_by': checkedBy,
      if (overruled != null) 'overruled': overruled,
      if (takenAt != null) 'taken_at': takenAt,
    });
  }

  TeachBackAttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? studySetId,
    Value<String>? section,
    Value<int>? sectionIndex,
    Value<String>? answer,
    Value<int>? covered,
    Value<int>? partly,
    Value<int>? total,
    Value<bool>? copied,
    Value<int>? flagCount,
    Value<String>? checkedBy,
    Value<String>? overruled,
    Value<DateTime>? takenAt,
  }) {
    return TeachBackAttemptsCompanion(
      id: id ?? this.id,
      studySetId: studySetId ?? this.studySetId,
      section: section ?? this.section,
      sectionIndex: sectionIndex ?? this.sectionIndex,
      answer: answer ?? this.answer,
      covered: covered ?? this.covered,
      partly: partly ?? this.partly,
      total: total ?? this.total,
      copied: copied ?? this.copied,
      flagCount: flagCount ?? this.flagCount,
      checkedBy: checkedBy ?? this.checkedBy,
      overruled: overruled ?? this.overruled,
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
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (sectionIndex.present) {
      map['section_index'] = Variable<int>(sectionIndex.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (covered.present) {
      map['covered'] = Variable<int>(covered.value);
    }
    if (partly.present) {
      map['partly'] = Variable<int>(partly.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (copied.present) {
      map['copied'] = Variable<bool>(copied.value);
    }
    if (flagCount.present) {
      map['flag_count'] = Variable<int>(flagCount.value);
    }
    if (checkedBy.present) {
      map['checked_by'] = Variable<String>(checkedBy.value);
    }
    if (overruled.present) {
      map['overruled'] = Variable<String>(overruled.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeachBackAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('section: $section, ')
          ..write('sectionIndex: $sectionIndex, ')
          ..write('answer: $answer, ')
          ..write('covered: $covered, ')
          ..write('partly: $partly, ')
          ..write('total: $total, ')
          ..write('copied: $copied, ')
          ..write('flagCount: $flagCount, ')
          ..write('checkedBy: $checkedBy, ')
          ..write('overruled: $overruled, ')
          ..write('takenAt: $takenAt')
          ..write(')'))
        .toString();
  }
}

class $TopicConceptsTable extends TopicConcepts
    with TableInfo<$TopicConceptsTable, TopicConceptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicConceptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conceptsMeta = const VerificationMeta(
    'concepts',
  );
  @override
  late final GeneratedColumn<String> concepts = GeneratedColumn<String>(
    'concepts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    studySetId,
    section,
    concepts,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topic_concepts';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicConceptRow> instance, {
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
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('concepts')) {
      context.handle(
        _conceptsMeta,
        concepts.isAcceptableOrUnknown(data['concepts']!, _conceptsMeta),
      );
    } else if (isInserting) {
      context.missing(_conceptsMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {studySetId, section},
  ];
  @override
  TopicConceptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicConceptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      studySetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}study_set_id'],
      )!,
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      )!,
      concepts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}concepts'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TopicConceptsTable createAlias(String alias) {
    return $TopicConceptsTable(attachedDatabase, alias);
  }
}

class TopicConceptRow extends DataClass implements Insertable<TopicConceptRow> {
  final int id;
  final int studySetId;
  final String section;
  final String concepts;
  final DateTime createdAt;
  const TopicConceptRow({
    required this.id,
    required this.studySetId,
    required this.section,
    required this.concepts,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['study_set_id'] = Variable<int>(studySetId);
    map['section'] = Variable<String>(section);
    map['concepts'] = Variable<String>(concepts);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TopicConceptsCompanion toCompanion(bool nullToAbsent) {
    return TopicConceptsCompanion(
      id: Value(id),
      studySetId: Value(studySetId),
      section: Value(section),
      concepts: Value(concepts),
      createdAt: Value(createdAt),
    );
  }

  factory TopicConceptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicConceptRow(
      id: serializer.fromJson<int>(json['id']),
      studySetId: serializer.fromJson<int>(json['studySetId']),
      section: serializer.fromJson<String>(json['section']),
      concepts: serializer.fromJson<String>(json['concepts']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studySetId': serializer.toJson<int>(studySetId),
      'section': serializer.toJson<String>(section),
      'concepts': serializer.toJson<String>(concepts),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TopicConceptRow copyWith({
    int? id,
    int? studySetId,
    String? section,
    String? concepts,
    DateTime? createdAt,
  }) => TopicConceptRow(
    id: id ?? this.id,
    studySetId: studySetId ?? this.studySetId,
    section: section ?? this.section,
    concepts: concepts ?? this.concepts,
    createdAt: createdAt ?? this.createdAt,
  );
  TopicConceptRow copyWithCompanion(TopicConceptsCompanion data) {
    return TopicConceptRow(
      id: data.id.present ? data.id.value : this.id,
      studySetId: data.studySetId.present
          ? data.studySetId.value
          : this.studySetId,
      section: data.section.present ? data.section.value : this.section,
      concepts: data.concepts.present ? data.concepts.value : this.concepts,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicConceptRow(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('section: $section, ')
          ..write('concepts: $concepts, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, studySetId, section, concepts, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicConceptRow &&
          other.id == this.id &&
          other.studySetId == this.studySetId &&
          other.section == this.section &&
          other.concepts == this.concepts &&
          other.createdAt == this.createdAt);
}

class TopicConceptsCompanion extends UpdateCompanion<TopicConceptRow> {
  final Value<int> id;
  final Value<int> studySetId;
  final Value<String> section;
  final Value<String> concepts;
  final Value<DateTime> createdAt;
  const TopicConceptsCompanion({
    this.id = const Value.absent(),
    this.studySetId = const Value.absent(),
    this.section = const Value.absent(),
    this.concepts = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TopicConceptsCompanion.insert({
    this.id = const Value.absent(),
    required int studySetId,
    required String section,
    required String concepts,
    this.createdAt = const Value.absent(),
  }) : studySetId = Value(studySetId),
       section = Value(section),
       concepts = Value(concepts);
  static Insertable<TopicConceptRow> custom({
    Expression<int>? id,
    Expression<int>? studySetId,
    Expression<String>? section,
    Expression<String>? concepts,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studySetId != null) 'study_set_id': studySetId,
      if (section != null) 'section': section,
      if (concepts != null) 'concepts': concepts,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TopicConceptsCompanion copyWith({
    Value<int>? id,
    Value<int>? studySetId,
    Value<String>? section,
    Value<String>? concepts,
    Value<DateTime>? createdAt,
  }) {
    return TopicConceptsCompanion(
      id: id ?? this.id,
      studySetId: studySetId ?? this.studySetId,
      section: section ?? this.section,
      concepts: concepts ?? this.concepts,
      createdAt: createdAt ?? this.createdAt,
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
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (concepts.present) {
      map['concepts'] = Variable<String>(concepts.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicConceptsCompanion(')
          ..write('id: $id, ')
          ..write('studySetId: $studySetId, ')
          ..write('section: $section, ')
          ..write('concepts: $concepts, ')
          ..write('createdAt: $createdAt')
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
  late final $ReadersTable readers = $ReadersTable(this);
  late final $StoriesTable stories = $StoriesTable(this);
  late final $ReadingAttemptsTable readingAttempts = $ReadingAttemptsTable(
    this,
  );
  late final $SavedWordsTable savedWords = $SavedWordsTable(this);
  late final $ReviewStatesTable reviewStates = $ReviewStatesTable(this);
  late final $ReviewLogTable reviewLog = $ReviewLogTable(this);
  late final $TeachBackAttemptsTable teachBackAttempts =
      $TeachBackAttemptsTable(this);
  late final $TopicConceptsTable topicConcepts = $TopicConceptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    studySets,
    questionRows,
    flashcardRows,
    attempts,
    readers,
    stories,
    readingAttempts,
    savedWords,
    reviewStates,
    reviewLog,
    teachBackAttempts,
    topicConcepts,
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
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'readers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reading_attempts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'readers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('saved_words', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'study_sets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_states', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'study_sets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('review_log', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'study_sets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('teach_back_attempts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'study_sets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('topic_concepts', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$StudySetsTableCreateCompanionBuilder = StudySetsCompanion Function({
  Value<int> id,
  required String title,
  Value<String> sourceType,
  Value<String> sourceText,
  Value<String> sourcePaths,
  Value<String> summary,
  Value<DateTime> createdAt,
});
typedef $$StudySetsTableUpdateCompanionBuilder = StudySetsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> sourceType,
  Value<String> sourceText,
  Value<String> sourcePaths,
  Value<String> summary,
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

  static MultiTypedResultKey<$ReviewStatesTable, List<ReviewState>>
  _reviewStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewStates,
    aliasName: 'study_sets__id__review_states__study_set_id',
  );

  $$ReviewStatesTableProcessedTableManager get reviewStatesRefs {
    final manager = $$ReviewStatesTableTableManager(
      $_db,
      $_db.reviewStates,
    ).filter((f) => f.studySetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewLogTable, List<ReviewEntry>>
  _reviewLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.reviewLog,
    aliasName: 'study_sets__id__review_log__study_set_id',
  );

  $$ReviewLogTableProcessedTableManager get reviewLogRefs {
    final manager = $$ReviewLogTableTableManager(
      $_db,
      $_db.reviewLog,
    ).filter((f) => f.studySetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewLogRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TeachBackAttemptsTable, List<TeachBackAttempt>>
  _teachBackAttemptsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.teachBackAttempts,
        aliasName: 'study_sets__id__teach_back_attempts__study_set_id',
      );

  $$TeachBackAttemptsTableProcessedTableManager get teachBackAttemptsRefs {
    final manager = $$TeachBackAttemptsTableTableManager(
      $_db,
      $_db.teachBackAttempts,
    ).filter((f) => f.studySetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _teachBackAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TopicConceptsTable, List<TopicConceptRow>>
  _topicConceptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.topicConcepts,
    aliasName: 'study_sets__id__topic_concepts__study_set_id',
  );

  $$TopicConceptsTableProcessedTableManager get topicConceptsRefs {
    final manager = $$TopicConceptsTableTableManager(
      $_db,
      $_db.topicConcepts,
    ).filter((f) => f.studySetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_topicConceptsRefsTable($_db));
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

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
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

  Expression<bool> reviewStatesRefs(
    Expression<bool> Function($$ReviewStatesTableFilterComposer f) f,
  ) {
    final $$ReviewStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewStates,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewStatesTableFilterComposer(
            $db: $db,
            $table: $db.reviewStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewLogRefs(
    Expression<bool> Function($$ReviewLogTableFilterComposer f) f,
  ) {
    final $$ReviewLogTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLog,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogTableFilterComposer(
            $db: $db,
            $table: $db.reviewLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> teachBackAttemptsRefs(
    Expression<bool> Function($$TeachBackAttemptsTableFilterComposer f) f,
  ) {
    final $$TeachBackAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.teachBackAttempts,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TeachBackAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.teachBackAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> topicConceptsRefs(
    Expression<bool> Function($$TopicConceptsTableFilterComposer f) f,
  ) {
    final $$TopicConceptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.topicConcepts,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicConceptsTableFilterComposer(
            $db: $db,
            $table: $db.topicConcepts,
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

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
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

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

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

  Expression<T> reviewStatesRefs<T extends Object>(
    Expression<T> Function($$ReviewStatesTableAnnotationComposer a) f,
  ) {
    final $$ReviewStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewStates,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewLogRefs<T extends Object>(
    Expression<T> Function($$ReviewLogTableAnnotationComposer a) f,
  ) {
    final $$ReviewLogTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviewLog,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewLogTableAnnotationComposer(
            $db: $db,
            $table: $db.reviewLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> teachBackAttemptsRefs<T extends Object>(
    Expression<T> Function($$TeachBackAttemptsTableAnnotationComposer a) f,
  ) {
    final $$TeachBackAttemptsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.teachBackAttempts,
          getReferencedColumn: (t) => t.studySetId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TeachBackAttemptsTableAnnotationComposer(
                $db: $db,
                $table: $db.teachBackAttempts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> topicConceptsRefs<T extends Object>(
    Expression<T> Function($$TopicConceptsTableAnnotationComposer a) f,
  ) {
    final $$TopicConceptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.topicConcepts,
      getReferencedColumn: (t) => t.studySetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicConceptsTableAnnotationComposer(
            $db: $db,
            $table: $db.topicConcepts,
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
            bool reviewStatesRefs,
            bool reviewLogRefs,
            bool teachBackAttemptsRefs,
            bool topicConceptsRefs,
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
                Value<String> summary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StudySetsCompanion(
                id: id,
                title: title,
                sourceType: sourceType,
                sourceText: sourceText,
                sourcePaths: sourcePaths,
                summary: summary,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String> sourceType = const Value.absent(),
                Value<String> sourceText = const Value.absent(),
                Value<String> sourcePaths = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StudySetsCompanion.insert(
                id: id,
                title: title,
                sourceType: sourceType,
                sourceText: sourceText,
                sourcePaths: sourcePaths,
                summary: summary,
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
                reviewStatesRefs = false,
                reviewLogRefs = false,
                teachBackAttemptsRefs = false,
                topicConceptsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (questionRowsRefs) db.questionRows,
                    if (flashcardRowsRefs) db.flashcardRows,
                    if (attemptsRefs) db.attempts,
                    if (reviewStatesRefs) db.reviewStates,
                    if (reviewLogRefs) db.reviewLog,
                    if (teachBackAttemptsRefs) db.teachBackAttempts,
                    if (topicConceptsRefs) db.topicConcepts,
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
                      if (reviewStatesRefs)
                        await $_getPrefetchedData<
                          StudySet,
                          $StudySetsTable,
                          ReviewState
                        >(
                          currentTable: table,
                          referencedTable: $$StudySetsTableReferences
                              ._reviewStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudySetsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studySetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewLogRefs)
                        await $_getPrefetchedData<
                          StudySet,
                          $StudySetsTable,
                          ReviewEntry
                        >(
                          currentTable: table,
                          referencedTable: $$StudySetsTableReferences
                              ._reviewLogRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudySetsTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewLogRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studySetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (teachBackAttemptsRefs)
                        await $_getPrefetchedData<
                          StudySet,
                          $StudySetsTable,
                          TeachBackAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$StudySetsTableReferences
                              ._teachBackAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudySetsTableReferences(
                                db,
                                table,
                                p0,
                              ).teachBackAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.studySetId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (topicConceptsRefs)
                        await $_getPrefetchedData<
                          StudySet,
                          $StudySetsTable,
                          TopicConceptRow
                        >(
                          currentTable: table,
                          referencedTable: $$StudySetsTableReferences
                              ._topicConceptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StudySetsTableReferences(
                                db,
                                table,
                                p0,
                              ).topicConceptsRefs,
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
        bool reviewStatesRefs,
        bool reviewLogRefs,
        bool teachBackAttemptsRefs,
        bool topicConceptsRefs,
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
      Value<String> source,
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
      Value<String> source,
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

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
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

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

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
                Value<String> source = const Value.absent(),
              }) => QuestionRowsCompanion(
                id: id,
                studySetId: studySetId,
                type: type,
                prompt: prompt,
                choices: choices,
                answerIndex: answerIndex,
                explanation: explanation,
                source: source,
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
                Value<String> source = const Value.absent(),
              }) => QuestionRowsCompanion.insert(
                id: id,
                studySetId: studySetId,
                type: type,
                prompt: prompt,
                choices: choices,
                answerIndex: answerIndex,
                explanation: explanation,
                source: source,
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
      Value<String> source,
    });
typedef $$FlashcardRowsTableUpdateCompanionBuilder =
    FlashcardRowsCompanion Function({
      Value<int> id,
      Value<int> studySetId,
      Value<String> front,
      Value<String> back,
      Value<String> source,
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

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
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

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

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
                Value<String> source = const Value.absent(),
              }) => FlashcardRowsCompanion(
                id: id,
                studySetId: studySetId,
                front: front,
                back: back,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studySetId,
                required String front,
                required String back,
                Value<String> source = const Value.absent(),
              }) => FlashcardRowsCompanion.insert(
                id: id,
                studySetId: studySetId,
                front: front,
                back: back,
                source: source,
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
typedef $$ReadersTableCreateCompanionBuilder = ReadersCompanion Function({
  Value<int> id,
  required String name,
  Value<int> level,
  Value<bool> placed,
  Value<DateTime> createdAt,
});
typedef $$ReadersTableUpdateCompanionBuilder = ReadersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> level,
  Value<bool> placed,
  Value<DateTime> createdAt,
});

final class $$ReadersTableReferences
    extends BaseReferences<_$AppDatabase, $ReadersTable, Reader> {
  $$ReadersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReadingAttemptsTable, List<ReadingAttempt>>
  _readingAttemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingAttempts,
    aliasName: 'readers__id__reading_attempts__reader_id',
  );

  $$ReadingAttemptsTableProcessedTableManager get readingAttemptsRefs {
    final manager = $$ReadingAttemptsTableTableManager(
      $_db,
      $_db.readingAttempts,
    ).filter((f) => f.readerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SavedWordsTable, List<SavedWord>>
  _savedWordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.savedWords,
    aliasName: 'readers__id__saved_words__reader_id',
  );

  $$SavedWordsTableProcessedTableManager get savedWordsRefs {
    final manager = $$SavedWordsTableTableManager(
      $_db,
      $_db.savedWords,
    ).filter((f) => f.readerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_savedWordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReadersTableFilterComposer
    extends Composer<_$AppDatabase, $ReadersTable> {
  $$ReadersTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get placed => $composableBuilder(
    column: $table.placed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> readingAttemptsRefs(
    Expression<bool> Function($$ReadingAttemptsTableFilterComposer f) f,
  ) {
    final $$ReadingAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingAttempts,
      getReferencedColumn: (t) => t.readerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.readingAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> savedWordsRefs(
    Expression<bool> Function($$SavedWordsTableFilterComposer f) f,
  ) {
    final $$SavedWordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedWords,
      getReferencedColumn: (t) => t.readerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedWordsTableFilterComposer(
            $db: $db,
            $table: $db.savedWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReadersTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadersTable> {
  $$ReadersTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get placed => $composableBuilder(
    column: $table.placed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadersTable> {
  $$ReadersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<bool> get placed =>
      $composableBuilder(column: $table.placed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> readingAttemptsRefs<T extends Object>(
    Expression<T> Function($$ReadingAttemptsTableAnnotationComposer a) f,
  ) {
    final $$ReadingAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingAttempts,
      getReferencedColumn: (t) => t.readerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> savedWordsRefs<T extends Object>(
    Expression<T> Function($$SavedWordsTableAnnotationComposer a) f,
  ) {
    final $$SavedWordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.savedWords,
      getReferencedColumn: (t) => t.readerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SavedWordsTableAnnotationComposer(
            $db: $db,
            $table: $db.savedWords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReadersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadersTable,
          Reader,
          $$ReadersTableFilterComposer,
          $$ReadersTableOrderingComposer,
          $$ReadersTableAnnotationComposer,
          $$ReadersTableCreateCompanionBuilder,
          $$ReadersTableUpdateCompanionBuilder,
          (Reader, $$ReadersTableReferences),
          Reader,
          PrefetchHooks Function({
            bool readingAttemptsRefs,
            bool savedWordsRefs,
          })
        > {
  $$ReadersTableTableManager(_$AppDatabase db, $ReadersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<bool> placed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadersCompanion(
                id: id,
                name: name,
                level: level,
                placed: placed,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> level = const Value.absent(),
                Value<bool> placed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReadersCompanion.insert(
                id: id,
                name: name,
                level: level,
                placed: placed,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadersTable, Reader>(table),
                  $$ReadersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({readingAttemptsRefs = false, savedWordsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (readingAttemptsRefs) db.readingAttempts,
                    if (savedWordsRefs) db.savedWords,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (readingAttemptsRefs)
                        await $_getPrefetchedData<
                          Reader,
                          $ReadersTable,
                          ReadingAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$ReadersTableReferences
                              ._readingAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReadersTableReferences(
                                db,
                                table,
                                p0,
                              ).readingAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.readerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (savedWordsRefs)
                        await $_getPrefetchedData<
                          Reader,
                          $ReadersTable,
                          SavedWord
                        >(
                          currentTable: table,
                          referencedTable: $$ReadersTableReferences
                              ._savedWordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReadersTableReferences(
                                db,
                                table,
                                p0,
                              ).savedWordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.readerId == item.id,
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

typedef $$ReadersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadersTable,
      Reader,
      $$ReadersTableFilterComposer,
      $$ReadersTableOrderingComposer,
      $$ReadersTableAnnotationComposer,
      $$ReadersTableCreateCompanionBuilder,
      $$ReadersTableUpdateCompanionBuilder,
      (Reader, $$ReadersTableReferences),
      Reader,
      PrefetchHooks Function({bool readingAttemptsRefs, bool savedWordsRefs})
    >;
typedef $$StoriesTableCreateCompanionBuilder = StoriesCompanion Function({
  Value<int> id,
  required int level,
  required String topic,
  required String title,
  required String paras,
  required String questions,
  Value<String> checks,
  required int pipeline,
  Value<String> source,
  Value<DateTime> createdAt,
});
typedef $$StoriesTableUpdateCompanionBuilder = StoriesCompanion Function({
  Value<int> id,
  Value<int> level,
  Value<String> topic,
  Value<String> title,
  Value<String> paras,
  Value<String> questions,
  Value<String> checks,
  Value<int> pipeline,
  Value<String> source,
  Value<DateTime> createdAt,
});

final class $$StoriesTableReferences
    extends BaseReferences<_$AppDatabase, $StoriesTable, StoryRow> {
  $$StoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReadingAttemptsTable, List<ReadingAttempt>>
  _readingAttemptsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.readingAttempts,
    aliasName: 'stories__id__reading_attempts__story_id',
  );

  $$ReadingAttemptsTableProcessedTableManager get readingAttemptsRefs {
    final manager = $$ReadingAttemptsTableTableManager(
      $_db,
      $_db.readingAttempts,
    ).filter((f) => f.storyId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _readingAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoriesTableFilterComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableFilterComposer({
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

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paras => $composableBuilder(
    column: $table.paras,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questions => $composableBuilder(
    column: $table.questions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checks => $composableBuilder(
    column: $table.checks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pipeline => $composableBuilder(
    column: $table.pipeline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> readingAttemptsRefs(
    Expression<bool> Function($$ReadingAttemptsTableFilterComposer f) f,
  ) {
    final $$ReadingAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingAttempts,
      getReferencedColumn: (t) => t.storyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.readingAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableOrderingComposer({
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

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paras => $composableBuilder(
    column: $table.paras,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questions => $composableBuilder(
    column: $table.questions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checks => $composableBuilder(
    column: $table.checks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pipeline => $composableBuilder(
    column: $table.pipeline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoriesTable> {
  $$StoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get paras =>
      $composableBuilder(column: $table.paras, builder: (column) => column);

  GeneratedColumn<String> get questions =>
      $composableBuilder(column: $table.questions, builder: (column) => column);

  GeneratedColumn<String> get checks =>
      $composableBuilder(column: $table.checks, builder: (column) => column);

  GeneratedColumn<int> get pipeline =>
      $composableBuilder(column: $table.pipeline, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> readingAttemptsRefs<T extends Object>(
    Expression<T> Function($$ReadingAttemptsTableAnnotationComposer a) f,
  ) {
    final $$ReadingAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.readingAttempts,
      getReferencedColumn: (t) => t.storyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadingAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.readingAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoriesTable,
          StoryRow,
          $$StoriesTableFilterComposer,
          $$StoriesTableOrderingComposer,
          $$StoriesTableAnnotationComposer,
          $$StoriesTableCreateCompanionBuilder,
          $$StoriesTableUpdateCompanionBuilder,
          (StoryRow, $$StoriesTableReferences),
          StoryRow,
          PrefetchHooks Function({bool readingAttemptsRefs})
        > {
  $$StoriesTableTableManager(_$AppDatabase db, $StoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> paras = const Value.absent(),
                Value<String> questions = const Value.absent(),
                Value<String> checks = const Value.absent(),
                Value<int> pipeline = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StoriesCompanion(
                id: id,
                level: level,
                topic: topic,
                title: title,
                paras: paras,
                questions: questions,
                checks: checks,
                pipeline: pipeline,
                source: source,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int level,
                required String topic,
                required String title,
                required String paras,
                required String questions,
                Value<String> checks = const Value.absent(),
                required int pipeline,
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => StoriesCompanion.insert(
                id: id,
                level: level,
                topic: topic,
                title: title,
                paras: paras,
                questions: questions,
                checks: checks,
                pipeline: pipeline,
                source: source,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoriesTable, StoryRow>(table),
                  $$StoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({readingAttemptsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (readingAttemptsRefs) db.readingAttempts,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (readingAttemptsRefs)
                    await $_getPrefetchedData<
                      StoryRow,
                      $StoriesTable,
                      ReadingAttempt
                    >(
                      currentTable: table,
                      referencedTable: $$StoriesTableReferences
                          ._readingAttemptsRefsTable(db),
                      managerFromTypedResult: (p0) => $$StoriesTableReferences(
                        db,
                        table,
                        p0,
                      ).readingAttemptsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.storyId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoriesTable,
      StoryRow,
      $$StoriesTableFilterComposer,
      $$StoriesTableOrderingComposer,
      $$StoriesTableAnnotationComposer,
      $$StoriesTableCreateCompanionBuilder,
      $$StoriesTableUpdateCompanionBuilder,
      (StoryRow, $$StoriesTableReferences),
      StoryRow,
      PrefetchHooks Function({bool readingAttemptsRefs})
    >;
typedef $$ReadingAttemptsTableCreateCompanionBuilder =
    ReadingAttemptsCompanion Function({
      Value<int> id,
      required int readerId,
      required int storyId,
      required int level,
      required int correct,
      required int total,
      Value<int> moved,
      Value<String> skills,
      Value<int?> wpm,
      Value<DateTime> takenAt,
    });
typedef $$ReadingAttemptsTableUpdateCompanionBuilder =
    ReadingAttemptsCompanion Function({
      Value<int> id,
      Value<int> readerId,
      Value<int> storyId,
      Value<int> level,
      Value<int> correct,
      Value<int> total,
      Value<int> moved,
      Value<String> skills,
      Value<int?> wpm,
      Value<DateTime> takenAt,
    });

final class $$ReadingAttemptsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReadingAttemptsTable, ReadingAttempt> {
  $$ReadingAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ReadersTable _readerIdTable(_$AppDatabase db) =>
      db.readers.createAlias('reading_attempts__reader_id__readers__id');

  $$ReadersTableProcessedTableManager get readerId {
    final $_column = $_itemColumn<int>('reader_id')!;

    final manager = $$ReadersTableTableManager(
      $_db,
      $_db.readers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_readerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StoriesTable _storyIdTable(_$AppDatabase db) =>
      db.stories.createAlias('reading_attempts__story_id__stories__id');

  $$StoriesTableProcessedTableManager get storyId {
    final $_column = $_itemColumn<int>('story_id')!;

    final manager = $$StoriesTableTableManager(
      $_db,
      $_db.stories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReadingAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingAttemptsTable> {
  $$ReadingAttemptsTableFilterComposer({
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

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get moved => $composableBuilder(
    column: $table.moved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skills => $composableBuilder(
    column: $table.skills,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wpm => $composableBuilder(
    column: $table.wpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ReadersTableFilterComposer get readerId {
    final $$ReadersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readerId,
      referencedTable: $db.readers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadersTableFilterComposer(
            $db: $db,
            $table: $db.readers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoriesTableFilterComposer get storyId {
    final $$StoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableFilterComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingAttemptsTable> {
  $$ReadingAttemptsTableOrderingComposer({
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

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moved => $composableBuilder(
    column: $table.moved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skills => $composableBuilder(
    column: $table.skills,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wpm => $composableBuilder(
    column: $table.wpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReadersTableOrderingComposer get readerId {
    final $$ReadersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readerId,
      referencedTable: $db.readers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadersTableOrderingComposer(
            $db: $db,
            $table: $db.readers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoriesTableOrderingComposer get storyId {
    final $$StoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableOrderingComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingAttemptsTable> {
  $$ReadingAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get moved =>
      $composableBuilder(column: $table.moved, builder: (column) => column);

  GeneratedColumn<String> get skills =>
      $composableBuilder(column: $table.skills, builder: (column) => column);

  GeneratedColumn<int> get wpm =>
      $composableBuilder(column: $table.wpm, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  $$ReadersTableAnnotationComposer get readerId {
    final $$ReadersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readerId,
      referencedTable: $db.readers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadersTableAnnotationComposer(
            $db: $db,
            $table: $db.readers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoriesTableAnnotationComposer get storyId {
    final $$StoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storyId,
      referencedTable: $db.stories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.stories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReadingAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingAttemptsTable,
          ReadingAttempt,
          $$ReadingAttemptsTableFilterComposer,
          $$ReadingAttemptsTableOrderingComposer,
          $$ReadingAttemptsTableAnnotationComposer,
          $$ReadingAttemptsTableCreateCompanionBuilder,
          $$ReadingAttemptsTableUpdateCompanionBuilder,
          (ReadingAttempt, $$ReadingAttemptsTableReferences),
          ReadingAttempt,
          PrefetchHooks Function({bool readerId, bool storyId})
        > {
  $$ReadingAttemptsTableTableManager(
    _$AppDatabase db,
    $ReadingAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> readerId = const Value.absent(),
                Value<int> storyId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> moved = const Value.absent(),
                Value<String> skills = const Value.absent(),
                Value<int?> wpm = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
              }) => ReadingAttemptsCompanion(
                id: id,
                readerId: readerId,
                storyId: storyId,
                level: level,
                correct: correct,
                total: total,
                moved: moved,
                skills: skills,
                wpm: wpm,
                takenAt: takenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int readerId,
                required int storyId,
                required int level,
                required int correct,
                required int total,
                Value<int> moved = const Value.absent(),
                Value<String> skills = const Value.absent(),
                Value<int?> wpm = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
              }) => ReadingAttemptsCompanion.insert(
                id: id,
                readerId: readerId,
                storyId: storyId,
                level: level,
                correct: correct,
                total: total,
                moved: moved,
                skills: skills,
                wpm: wpm,
                takenAt: takenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingAttemptsTable, ReadingAttempt>(table),
                  $$ReadingAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({readerId = false, storyId = false}) {
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
                    if (readerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.readerId,
                        referencedTable: $$ReadingAttemptsTableReferences
                            ._readerIdTable(db),
                        referencedColumn: $$ReadingAttemptsTableReferences
                            ._readerIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (storyId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.storyId,
                        referencedTable: $$ReadingAttemptsTableReferences
                            ._storyIdTable(db),
                        referencedColumn: $$ReadingAttemptsTableReferences
                            ._storyIdTable(db)
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

typedef $$ReadingAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingAttemptsTable,
      ReadingAttempt,
      $$ReadingAttemptsTableFilterComposer,
      $$ReadingAttemptsTableOrderingComposer,
      $$ReadingAttemptsTableAnnotationComposer,
      $$ReadingAttemptsTableCreateCompanionBuilder,
      $$ReadingAttemptsTableUpdateCompanionBuilder,
      (ReadingAttempt, $$ReadingAttemptsTableReferences),
      ReadingAttempt,
      PrefetchHooks Function({bool readerId, bool storyId})
    >;
typedef $$SavedWordsTableCreateCompanionBuilder = SavedWordsCompanion Function({
  Value<int> id,
  required int readerId,
  required String word,
  required String meaning,
  Value<String?> synonym,
  required String sentence,
  Value<int> times,
  Value<int> known,
  Value<DateTime> savedAt,
});
typedef $$SavedWordsTableUpdateCompanionBuilder = SavedWordsCompanion Function({
  Value<int> id,
  Value<int> readerId,
  Value<String> word,
  Value<String> meaning,
  Value<String?> synonym,
  Value<String> sentence,
  Value<int> times,
  Value<int> known,
  Value<DateTime> savedAt,
});

final class $$SavedWordsTableReferences
    extends BaseReferences<_$AppDatabase, $SavedWordsTable, SavedWord> {
  $$SavedWordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReadersTable _readerIdTable(_$AppDatabase db) =>
      db.readers.createAlias('saved_words__reader_id__readers__id');

  $$ReadersTableProcessedTableManager get readerId {
    final $_column = $_itemColumn<int>('reader_id')!;

    final manager = $$ReadersTableTableManager(
      $_db,
      $_db.readers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_readerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SavedWordsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedWordsTable> {
  $$SavedWordsTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get synonym => $composableBuilder(
    column: $table.synonym,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentence => $composableBuilder(
    column: $table.sentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get times => $composableBuilder(
    column: $table.times,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get known => $composableBuilder(
    column: $table.known,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ReadersTableFilterComposer get readerId {
    final $$ReadersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readerId,
      referencedTable: $db.readers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadersTableFilterComposer(
            $db: $db,
            $table: $db.readers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedWordsTable> {
  $$SavedWordsTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get synonym => $composableBuilder(
    column: $table.synonym,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentence => $composableBuilder(
    column: $table.sentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get times => $composableBuilder(
    column: $table.times,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get known => $composableBuilder(
    column: $table.known,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReadersTableOrderingComposer get readerId {
    final $$ReadersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readerId,
      referencedTable: $db.readers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadersTableOrderingComposer(
            $db: $db,
            $table: $db.readers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedWordsTable> {
  $$SavedWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get synonym =>
      $composableBuilder(column: $table.synonym, builder: (column) => column);

  GeneratedColumn<String> get sentence =>
      $composableBuilder(column: $table.sentence, builder: (column) => column);

  GeneratedColumn<int> get times =>
      $composableBuilder(column: $table.times, builder: (column) => column);

  GeneratedColumn<int> get known =>
      $composableBuilder(column: $table.known, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);

  $$ReadersTableAnnotationComposer get readerId {
    final $$ReadersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.readerId,
      referencedTable: $db.readers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReadersTableAnnotationComposer(
            $db: $db,
            $table: $db.readers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SavedWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedWordsTable,
          SavedWord,
          $$SavedWordsTableFilterComposer,
          $$SavedWordsTableOrderingComposer,
          $$SavedWordsTableAnnotationComposer,
          $$SavedWordsTableCreateCompanionBuilder,
          $$SavedWordsTableUpdateCompanionBuilder,
          (SavedWord, $$SavedWordsTableReferences),
          SavedWord,
          PrefetchHooks Function({bool readerId})
        > {
  $$SavedWordsTableTableManager(_$AppDatabase db, $SavedWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> readerId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String?> synonym = const Value.absent(),
                Value<String> sentence = const Value.absent(),
                Value<int> times = const Value.absent(),
                Value<int> known = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => SavedWordsCompanion(
                id: id,
                readerId: readerId,
                word: word,
                meaning: meaning,
                synonym: synonym,
                sentence: sentence,
                times: times,
                known: known,
                savedAt: savedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int readerId,
                required String word,
                required String meaning,
                Value<String?> synonym = const Value.absent(),
                required String sentence,
                Value<int> times = const Value.absent(),
                Value<int> known = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => SavedWordsCompanion.insert(
                id: id,
                readerId: readerId,
                word: word,
                meaning: meaning,
                synonym: synonym,
                sentence: sentence,
                times: times,
                known: known,
                savedAt: savedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedWordsTable, SavedWord>(table),
                  $$SavedWordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({readerId = false}) {
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
                    if (readerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.readerId,
                        referencedTable: $$SavedWordsTableReferences
                            ._readerIdTable(db),
                        referencedColumn: $$SavedWordsTableReferences
                            ._readerIdTable(db)
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

typedef $$SavedWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedWordsTable,
      SavedWord,
      $$SavedWordsTableFilterComposer,
      $$SavedWordsTableOrderingComposer,
      $$SavedWordsTableAnnotationComposer,
      $$SavedWordsTableCreateCompanionBuilder,
      $$SavedWordsTableUpdateCompanionBuilder,
      (SavedWord, $$SavedWordsTableReferences),
      SavedWord,
      PrefetchHooks Function({bool readerId})
    >;
typedef $$ReviewStatesTableCreateCompanionBuilder =
    ReviewStatesCompanion Function({
      Value<int> id,
      required String kind,
      required int itemId,
      required int studySetId,
      Value<int> box,
      Value<DateTime?> dueDay,
      Value<DateTime?> lastAt,
      Value<int> streak,
      Value<int> lapses,
    });
typedef $$ReviewStatesTableUpdateCompanionBuilder =
    ReviewStatesCompanion Function({
      Value<int> id,
      Value<String> kind,
      Value<int> itemId,
      Value<int> studySetId,
      Value<int> box,
      Value<DateTime?> dueDay,
      Value<DateTime?> lastAt,
      Value<int> streak,
      Value<int> lapses,
    });

final class $$ReviewStatesTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewStatesTable, ReviewState> {
  $$ReviewStatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StudySetsTable _studySetIdTable(_$AppDatabase db) =>
      db.studySets.createAlias('review_states__study_set_id__study_sets__id');

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

class $$ReviewStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewStatesTable> {
  $$ReviewStatesTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
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

class $$ReviewStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewStatesTable> {
  $$ReviewStatesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get box => $composableBuilder(
    column: $table.box,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAt => $composableBuilder(
    column: $table.lastAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
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

class $$ReviewStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewStatesTable> {
  $$ReviewStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get box =>
      $composableBuilder(column: $table.box, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAt =>
      $composableBuilder(column: $table.lastAt, builder: (column) => column);

  GeneratedColumn<int> get streak =>
      $composableBuilder(column: $table.streak, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

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

class $$ReviewStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewStatesTable,
          ReviewState,
          $$ReviewStatesTableFilterComposer,
          $$ReviewStatesTableOrderingComposer,
          $$ReviewStatesTableAnnotationComposer,
          $$ReviewStatesTableCreateCompanionBuilder,
          $$ReviewStatesTableUpdateCompanionBuilder,
          (ReviewState, $$ReviewStatesTableReferences),
          ReviewState,
          PrefetchHooks Function({bool studySetId})
        > {
  $$ReviewStatesTableTableManager(_$AppDatabase db, $ReviewStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> studySetId = const Value.absent(),
                Value<int> box = const Value.absent(),
                Value<DateTime?> dueDay = const Value.absent(),
                Value<DateTime?> lastAt = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<int> lapses = const Value.absent(),
              }) => ReviewStatesCompanion(
                id: id,
                kind: kind,
                itemId: itemId,
                studySetId: studySetId,
                box: box,
                dueDay: dueDay,
                lastAt: lastAt,
                streak: streak,
                lapses: lapses,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required int itemId,
                required int studySetId,
                Value<int> box = const Value.absent(),
                Value<DateTime?> dueDay = const Value.absent(),
                Value<DateTime?> lastAt = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<int> lapses = const Value.absent(),
              }) => ReviewStatesCompanion.insert(
                id: id,
                kind: kind,
                itemId: itemId,
                studySetId: studySetId,
                box: box,
                dueDay: dueDay,
                lastAt: lastAt,
                streak: streak,
                lapses: lapses,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewStatesTable, ReviewState>(table),
                  $$ReviewStatesTableReferences(db, table, e),
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
                        referencedTable: $$ReviewStatesTableReferences
                            ._studySetIdTable(db),
                        referencedColumn: $$ReviewStatesTableReferences
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

typedef $$ReviewStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewStatesTable,
      ReviewState,
      $$ReviewStatesTableFilterComposer,
      $$ReviewStatesTableOrderingComposer,
      $$ReviewStatesTableAnnotationComposer,
      $$ReviewStatesTableCreateCompanionBuilder,
      $$ReviewStatesTableUpdateCompanionBuilder,
      (ReviewState, $$ReviewStatesTableReferences),
      ReviewState,
      PrefetchHooks Function({bool studySetId})
    >;
typedef $$ReviewLogTableCreateCompanionBuilder = ReviewLogCompanion Function({
  Value<int> id,
  required String kind,
  required int itemId,
  required int studySetId,
  required bool correct,
  Value<int?> chosen,
  required String mode,
  Value<DateTime> at,
});
typedef $$ReviewLogTableUpdateCompanionBuilder = ReviewLogCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<int> itemId,
  Value<int> studySetId,
  Value<bool> correct,
  Value<int?> chosen,
  Value<String> mode,
  Value<DateTime> at,
});

final class $$ReviewLogTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewLogTable, ReviewEntry> {
  $$ReviewLogTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StudySetsTable _studySetIdTable(_$AppDatabase db) =>
      db.studySets.createAlias('review_log__study_set_id__study_sets__id');

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

class $$ReviewLogTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chosen => $composableBuilder(
    column: $table.chosen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
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

class $$ReviewLogTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chosen => $composableBuilder(
    column: $table.chosen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
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

class $$ReviewLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogTable> {
  $$ReviewLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<bool> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get chosen =>
      $composableBuilder(column: $table.chosen, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);

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

class $$ReviewLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogTable,
          ReviewEntry,
          $$ReviewLogTableFilterComposer,
          $$ReviewLogTableOrderingComposer,
          $$ReviewLogTableAnnotationComposer,
          $$ReviewLogTableCreateCompanionBuilder,
          $$ReviewLogTableUpdateCompanionBuilder,
          (ReviewEntry, $$ReviewLogTableReferences),
          ReviewEntry,
          PrefetchHooks Function({bool studySetId})
        > {
  $$ReviewLogTableTableManager(_$AppDatabase db, $ReviewLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<int> studySetId = const Value.absent(),
                Value<bool> correct = const Value.absent(),
                Value<int?> chosen = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => ReviewLogCompanion(
                id: id,
                kind: kind,
                itemId: itemId,
                studySetId: studySetId,
                correct: correct,
                chosen: chosen,
                mode: mode,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required int itemId,
                required int studySetId,
                required bool correct,
                Value<int?> chosen = const Value.absent(),
                required String mode,
                Value<DateTime> at = const Value.absent(),
              }) => ReviewLogCompanion.insert(
                id: id,
                kind: kind,
                itemId: itemId,
                studySetId: studySetId,
                correct: correct,
                chosen: chosen,
                mode: mode,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewLogTable, ReviewEntry>(table),
                  $$ReviewLogTableReferences(db, table, e),
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
                        referencedTable: $$ReviewLogTableReferences
                            ._studySetIdTable(db),
                        referencedColumn: $$ReviewLogTableReferences
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

typedef $$ReviewLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogTable,
      ReviewEntry,
      $$ReviewLogTableFilterComposer,
      $$ReviewLogTableOrderingComposer,
      $$ReviewLogTableAnnotationComposer,
      $$ReviewLogTableCreateCompanionBuilder,
      $$ReviewLogTableUpdateCompanionBuilder,
      (ReviewEntry, $$ReviewLogTableReferences),
      ReviewEntry,
      PrefetchHooks Function({bool studySetId})
    >;
typedef $$TeachBackAttemptsTableCreateCompanionBuilder =
    TeachBackAttemptsCompanion Function({
      Value<int> id,
      required int studySetId,
      required String section,
      Value<int> sectionIndex,
      required String answer,
      Value<int> covered,
      Value<int> partly,
      Value<int> total,
      Value<bool> copied,
      Value<int> flagCount,
      Value<String> checkedBy,
      Value<String> overruled,
      Value<DateTime> takenAt,
    });
typedef $$TeachBackAttemptsTableUpdateCompanionBuilder =
    TeachBackAttemptsCompanion Function({
      Value<int> id,
      Value<int> studySetId,
      Value<String> section,
      Value<int> sectionIndex,
      Value<String> answer,
      Value<int> covered,
      Value<int> partly,
      Value<int> total,
      Value<bool> copied,
      Value<int> flagCount,
      Value<String> checkedBy,
      Value<String> overruled,
      Value<DateTime> takenAt,
    });

final class $$TeachBackAttemptsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TeachBackAttemptsTable,
          TeachBackAttempt
        > {
  $$TeachBackAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudySetsTable _studySetIdTable(_$AppDatabase db) => db.studySets
      .createAlias('teach_back_attempts__study_set_id__study_sets__id');

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

class $$TeachBackAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $TeachBackAttemptsTable> {
  $$TeachBackAttemptsTableFilterComposer({
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

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get covered => $composableBuilder(
    column: $table.covered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get partly => $composableBuilder(
    column: $table.partly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get copied => $composableBuilder(
    column: $table.copied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get flagCount => $composableBuilder(
    column: $table.flagCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkedBy => $composableBuilder(
    column: $table.checkedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overruled => $composableBuilder(
    column: $table.overruled,
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

class $$TeachBackAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $TeachBackAttemptsTable> {
  $$TeachBackAttemptsTableOrderingComposer({
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

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get covered => $composableBuilder(
    column: $table.covered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get partly => $composableBuilder(
    column: $table.partly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get copied => $composableBuilder(
    column: $table.copied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get flagCount => $composableBuilder(
    column: $table.flagCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkedBy => $composableBuilder(
    column: $table.checkedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overruled => $composableBuilder(
    column: $table.overruled,
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

class $$TeachBackAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeachBackAttemptsTable> {
  $$TeachBackAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<int> get sectionIndex => $composableBuilder(
    column: $table.sectionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<int> get covered =>
      $composableBuilder(column: $table.covered, builder: (column) => column);

  GeneratedColumn<int> get partly =>
      $composableBuilder(column: $table.partly, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<bool> get copied =>
      $composableBuilder(column: $table.copied, builder: (column) => column);

  GeneratedColumn<int> get flagCount =>
      $composableBuilder(column: $table.flagCount, builder: (column) => column);

  GeneratedColumn<String> get checkedBy =>
      $composableBuilder(column: $table.checkedBy, builder: (column) => column);

  GeneratedColumn<String> get overruled =>
      $composableBuilder(column: $table.overruled, builder: (column) => column);

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

class $$TeachBackAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TeachBackAttemptsTable,
          TeachBackAttempt,
          $$TeachBackAttemptsTableFilterComposer,
          $$TeachBackAttemptsTableOrderingComposer,
          $$TeachBackAttemptsTableAnnotationComposer,
          $$TeachBackAttemptsTableCreateCompanionBuilder,
          $$TeachBackAttemptsTableUpdateCompanionBuilder,
          (TeachBackAttempt, $$TeachBackAttemptsTableReferences),
          TeachBackAttempt,
          PrefetchHooks Function({bool studySetId})
        > {
  $$TeachBackAttemptsTableTableManager(
    _$AppDatabase db,
    $TeachBackAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeachBackAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeachBackAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeachBackAttemptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studySetId = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<int> sectionIndex = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<int> covered = const Value.absent(),
                Value<int> partly = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<bool> copied = const Value.absent(),
                Value<int> flagCount = const Value.absent(),
                Value<String> checkedBy = const Value.absent(),
                Value<String> overruled = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
              }) => TeachBackAttemptsCompanion(
                id: id,
                studySetId: studySetId,
                section: section,
                sectionIndex: sectionIndex,
                answer: answer,
                covered: covered,
                partly: partly,
                total: total,
                copied: copied,
                flagCount: flagCount,
                checkedBy: checkedBy,
                overruled: overruled,
                takenAt: takenAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studySetId,
                required String section,
                Value<int> sectionIndex = const Value.absent(),
                required String answer,
                Value<int> covered = const Value.absent(),
                Value<int> partly = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<bool> copied = const Value.absent(),
                Value<int> flagCount = const Value.absent(),
                Value<String> checkedBy = const Value.absent(),
                Value<String> overruled = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
              }) => TeachBackAttemptsCompanion.insert(
                id: id,
                studySetId: studySetId,
                section: section,
                sectionIndex: sectionIndex,
                answer: answer,
                covered: covered,
                partly: partly,
                total: total,
                copied: copied,
                flagCount: flagCount,
                checkedBy: checkedBy,
                overruled: overruled,
                takenAt: takenAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TeachBackAttemptsTable, TeachBackAttempt>(table),
                  $$TeachBackAttemptsTableReferences(db, table, e),
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
                        referencedTable: $$TeachBackAttemptsTableReferences
                            ._studySetIdTable(db),
                        referencedColumn: $$TeachBackAttemptsTableReferences
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

typedef $$TeachBackAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TeachBackAttemptsTable,
      TeachBackAttempt,
      $$TeachBackAttemptsTableFilterComposer,
      $$TeachBackAttemptsTableOrderingComposer,
      $$TeachBackAttemptsTableAnnotationComposer,
      $$TeachBackAttemptsTableCreateCompanionBuilder,
      $$TeachBackAttemptsTableUpdateCompanionBuilder,
      (TeachBackAttempt, $$TeachBackAttemptsTableReferences),
      TeachBackAttempt,
      PrefetchHooks Function({bool studySetId})
    >;
typedef $$TopicConceptsTableCreateCompanionBuilder =
    TopicConceptsCompanion Function({
      Value<int> id,
      required int studySetId,
      required String section,
      required String concepts,
      Value<DateTime> createdAt,
    });
typedef $$TopicConceptsTableUpdateCompanionBuilder =
    TopicConceptsCompanion Function({
      Value<int> id,
      Value<int> studySetId,
      Value<String> section,
      Value<String> concepts,
      Value<DateTime> createdAt,
    });

final class $$TopicConceptsTableReferences
    extends
        BaseReferences<_$AppDatabase, $TopicConceptsTable, TopicConceptRow> {
  $$TopicConceptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StudySetsTable _studySetIdTable(_$AppDatabase db) =>
      db.studySets.createAlias('topic_concepts__study_set_id__study_sets__id');

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

class $$TopicConceptsTableFilterComposer
    extends Composer<_$AppDatabase, $TopicConceptsTable> {
  $$TopicConceptsTableFilterComposer({
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

  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get concepts => $composableBuilder(
    column: $table.concepts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$TopicConceptsTableOrderingComposer
    extends Composer<_$AppDatabase, $TopicConceptsTable> {
  $$TopicConceptsTableOrderingComposer({
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

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get concepts => $composableBuilder(
    column: $table.concepts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
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

class $$TopicConceptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TopicConceptsTable> {
  $$TopicConceptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get concepts =>
      $composableBuilder(column: $table.concepts, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

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

class $$TopicConceptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TopicConceptsTable,
          TopicConceptRow,
          $$TopicConceptsTableFilterComposer,
          $$TopicConceptsTableOrderingComposer,
          $$TopicConceptsTableAnnotationComposer,
          $$TopicConceptsTableCreateCompanionBuilder,
          $$TopicConceptsTableUpdateCompanionBuilder,
          (TopicConceptRow, $$TopicConceptsTableReferences),
          TopicConceptRow,
          PrefetchHooks Function({bool studySetId})
        > {
  $$TopicConceptsTableTableManager(_$AppDatabase db, $TopicConceptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicConceptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicConceptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicConceptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> studySetId = const Value.absent(),
                Value<String> section = const Value.absent(),
                Value<String> concepts = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TopicConceptsCompanion(
                id: id,
                studySetId: studySetId,
                section: section,
                concepts: concepts,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int studySetId,
                required String section,
                required String concepts,
                Value<DateTime> createdAt = const Value.absent(),
              }) => TopicConceptsCompanion.insert(
                id: id,
                studySetId: studySetId,
                section: section,
                concepts: concepts,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TopicConceptsTable, TopicConceptRow>(table),
                  $$TopicConceptsTableReferences(db, table, e),
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
                        referencedTable: $$TopicConceptsTableReferences
                            ._studySetIdTable(db),
                        referencedColumn: $$TopicConceptsTableReferences
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

typedef $$TopicConceptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TopicConceptsTable,
      TopicConceptRow,
      $$TopicConceptsTableFilterComposer,
      $$TopicConceptsTableOrderingComposer,
      $$TopicConceptsTableAnnotationComposer,
      $$TopicConceptsTableCreateCompanionBuilder,
      $$TopicConceptsTableUpdateCompanionBuilder,
      (TopicConceptRow, $$TopicConceptsTableReferences),
      TopicConceptRow,
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
  $$ReadersTableTableManager get readers =>
      $$ReadersTableTableManager(_db, _db.readers);
  $$StoriesTableTableManager get stories =>
      $$StoriesTableTableManager(_db, _db.stories);
  $$ReadingAttemptsTableTableManager get readingAttempts =>
      $$ReadingAttemptsTableTableManager(_db, _db.readingAttempts);
  $$SavedWordsTableTableManager get savedWords =>
      $$SavedWordsTableTableManager(_db, _db.savedWords);
  $$ReviewStatesTableTableManager get reviewStates =>
      $$ReviewStatesTableTableManager(_db, _db.reviewStates);
  $$ReviewLogTableTableManager get reviewLog =>
      $$ReviewLogTableTableManager(_db, _db.reviewLog);
  $$TeachBackAttemptsTableTableManager get teachBackAttempts =>
      $$TeachBackAttemptsTableTableManager(_db, _db.teachBackAttempts);
  $$TopicConceptsTableTableManager get topicConcepts =>
      $$TopicConceptsTableTableManager(_db, _db.topicConcepts);
}
