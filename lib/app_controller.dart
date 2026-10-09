import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/ai_engine.dart';
import 'ai/llm_ai_engine.dart';
import 'domain/card_assist.dart';
import 'data/repository.dart';
import 'domain/models.dart';
import 'domain/source_attach.dart';
import 'domain/source_ref.dart';
import 'domain/summary.dart';
import 'study/teach_judge.dart';
import 'models/device_profiler.dart';
import 'models/model_manager.dart';
import 'models/tier.dart';

class ChatFailed implements Exception {
  ChatFailed(this.message);
  final String message;
  @override
  String toString() => message;
}

class SummaryFailed implements Exception {
  SummaryFailed(this.message);
  final String message;
  @override
  String toString() => message;
}

class AppController extends ChangeNotifier implements TeachBackModel {
  AppController({
    required this.tiers,
    required this.profiler,
    required this.models,
    required this.repo,
    required this.engineFactory,
    required this.prefs,
  });

  final TierTable tiers;
  final DeviceProfiler profiler;
  final ModelManager models;
  final StudyRepository repo;
  final AiEngine Function(Tier, File) engineFactory;
  final SharedPreferences prefs;

  Tier? tier;
  bool modelReady = false;
  double? downloadFraction;
  bool generating = false;
  double generationFraction = 0;
  bool summarizing = false;
  double summaryFraction = 0;
  String? error;
  Tier? fallbackOffer;
  bool storageTooLow = false;
  ThemeMode themeMode = ThemeMode.system;

  DeviceProfile? _device;
  AiEngine? _engine;
  String? _engineTier;

  Future<void> init() async {
    _device = await profiler.read();
    final saved = prefs.getString('tier');
    tier = tiers.tiers.where((t) => t.id == saved).firstOrNull ?? tiers.pick(_device!.ramMb);
    modelReady = await models.isInstalled(tier!);
    if (modelReady) {
      // Only once the current model is in place, so nobody is left with none.
      try {
        await models.removeUnused(tiers.tiers);
      } catch (_) {
        // the old files just stay until the next start
      }
    }
    themeMode = ThemeMode.values.asNameMap()[prefs.getString('theme')] ?? ThemeMode.system;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    await prefs.setString('theme', m.name);
    notifyListeners();
  }

  /// The Groq API key; while it is set and there is a connection, Groq answers
  /// and the local model is the offline fallback.
  String get groqKey => prefs.getString('groq_key') ?? '';

  Future<void> setGroqKey(String key) async {
    key = key.trim();
    if (key.isEmpty) {
      await prefs.remove('groq_key');
    } else {
      await prefs.setString('groq_key', key);
    }
    notifyListeners();
  }

  Tier get recommended => tiers.pick(_device!.ramMb);

  Future<void> chooseTier(Tier t) async {
    tier = t;
    await prefs.setString('tier', t.id);
    modelReady = await models.isInstalled(t);
    storageTooLow = false;
    error = null;
    await _dropEngine();
    notifyListeners();
  }

  Future<void> downloadModel() async {
    final t = tier!;
    if (!tiers.fitsStorage(t, _device!.freeStorageMb)) {
      storageTooLow = true;
      notifyListeners();
      return;
    }
    storageTooLow = false;
    error = null;
    downloadFraction = 0;
    notifyListeners();
    try {
      await for (final p in models.install(t)) {
        downloadFraction = p.fraction;
        notifyListeners();
      }
      modelReady = true;
    } catch (e) {
      error = 'Download failed: $e. Reconnect and try again to resume.';
    } finally {
      downloadFraction = null;
      notifyListeners();
    }
  }

  Future<int?> generate({
    required String title,
    required String notes,
    String sourceType = 'text',
    List<String> sourcePaths = const [],
  }) async {
    if (notes.trim().isEmpty) {
      error = 'No text to study from. Add or edit the notes first.';
      notifyListeners();
      return null;
    }
    generating = true;
    generationFraction = 0;
    error = null;
    notifyListeners();
    try {
      final engine = await _engineForTier();
      void progress(double from, double span, double f) {
        generationFraction = from + span * f;
        notifyListeners();
      }

      // The lesson comes first and is saved with the set; the flashcards and
      // quiz are made from it. If no lesson can be made, they come from the notes.
      LessonSummary? lesson;
      try {
        lesson = await engine.summarize(notes, onProgress: (f) => progress(0, 0.6, f));
      } on GenerationFailed {
        lesson = null;
      }
      GeneratedSet set;
      if (lesson == null) {
        set = await engine.generate(notes, onProgress: (f) => progress(0, 1, f));
      } else {
        try {
          set = await engine.generate(lesson.toStudyText(),
              verifyIn: notes, onProgress: (f) => progress(0.6, 0.4, f));
        } on GenerationFailed {
          set = await engine.generate(notes, onProgress: (f) => progress(0.6, 0.4, f));
        }
      }
      // Each piece of the lesson, each card and each question gets the page it
      // rests on, found in the pages of the file (none, for files without pages).
      final locator = _locatorFor(notes);
      return await repo.saveSet(title, attachSources(set, locator),
          sourceType: sourceType,
          sourceText: notes,
          sourcePaths: sourcePaths,
          summary: lesson?.withSources(locator));
    } on ModelUnavailableException {
      await _dropEngine();
      fallbackOffer = tiers.lower(tier!);
      error = fallbackOffer == null
          ? 'The AI model cannot run on this device.'
          : 'This computer ran out of memory for this model. Switch to a smaller one?';
      return null;
    } on GenerationFailed catch (e) {
      error = e.toString();
      return null;
    } finally {
      generating = false;
      notifyListeners();
    }
  }

  /// Tutor chat: answers the last user turn in [history] from [notes].
  /// Throws [ChatFailed] with a message fit to show the user.
  Future<String> ask(String notes, List<ChatTurn> history) async {
    try {
      return await (await _engineForTier()).ask(notes, history);
    } on ModelUnavailableException {
      await _dropEngine();
      throw ChatFailed('The AI model could not run. Close other apps and try again.');
    } catch (e) {
      throw ChatFailed("Couldn't get an answer, try again.");
    }
  }

  /// A suggestion for the missing side of a flashcard (marked with where it came from): the definition for [term], or the
  /// term for [definition], with the set's [notes] for context. Throws
  /// [CardAssistFailed] with a message fit to show the user.
  Future<CardSuggestion> suggestCard({
    required AssistField want,
    String term = '',
    String definition = '',
    String notes = '',
    String setTitle = '',
  }) async {
    final given = want == AssistField.definition ? term : definition;
    if (given.trim().isEmpty) {
      throw CardAssistFailed(want == AssistField.definition
          ? 'Type the term first, then ask the AI for its definition.'
          : 'Type the definition first, then ask the AI for the term.');
    }
    if (!modelReady) throw CardAssistFailed('The AI model is not set up yet. Open Settings to download it.');
    try {
      final reply = await (await runtime()).chat(
        buildCardAssistMessages(
            want: want, term: term, definition: definition, notes: notes, setTitle: setTitle),
        maxTokens: 160,
        temperature: 0.2,
        schema: cardAssistSchema(want),
      );
      var s = parseCardAssist(reply, want);
      if (s.isEmpty) {
        throw CardAssistFailed("The AI wasn't sure about that one. Try adding a little more detail, or write it yourself.");
      }
      if (want == AssistField.definition) s = withoutEchoedTerm(s, term);
      // The subject is the typed term, or for a suggested term the term itself.
      return CardSuggestion(s, fromNotes: mentionedIn(want == AssistField.definition ? term : s, notes));
    } on CardAssistFailed {
      rethrow;
    } on ModelUnavailableException {
      await _dropEngine();
      throw CardAssistFailed('The AI model could not run. Close other apps and try again.');
    } on FormatException {
      throw CardAssistFailed("The AI's answer was not usable. Try again.");
    } catch (_) {
      throw CardAssistFailed("Couldn't get a suggestion. Try again.");
    }
  }

  /// The current tier's model server, shared with Kulay so only one runs.
  Future<LlmRuntime> runtime() async {
    final e = await _engineForTier();
    if (e is LlmAiEngine) return e.runtime;
    throw ModelUnavailableException('no model server for this engine');
  }

  /// Turns [notes] into a study lesson. [summarizing] and [summaryFraction]
  /// report progress. Throws [SummaryFailed] with a message fit to show the user.
  Future<LessonSummary> summarize(String notes) async {
    if (notes.trim().isEmpty) {
      throw SummaryFailed('No text to summarize. Add or edit the notes first.');
    }
    summarizing = true;
    summaryFraction = 0;
    notifyListeners();
    try {
      final lesson = await (await _engineForTier()).summarize(notes, onProgress: (f) {
        summaryFraction = f;
        notifyListeners();
      });
      return lesson.withSources(_locatorFor(notes));
    } on ModelUnavailableException {
      await _dropEngine();
      throw SummaryFailed('The AI model could not run. Close other apps and try again.');
    } on GenerationFailed {
      throw SummaryFailed("Couldn't summarize this, try again.");
    } finally {
      summarizing = false;
      notifyListeners();
    }
  }

  // ---- Teach-Back: the model's part. It never throws: if the model cannot be used,
  // the check falls back to comparing words.

  @override
  bool get available => modelReady && tier != null;

  /// The smallest model writes the key ideas but is not asked to judge.
  @override
  bool get canJudge => available && tier!.id != 'low';

  @override
  Future<List<String>> concepts(String slideText, {String? topic}) async {
    if (!available) return const [];
    try {
      return await (await _engineForTier()).topicConcepts(slideText, topic: topic);
    } on ModelUnavailableException {
      await _dropEngine();
      return const [];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<TeachBackJudgement?> judge({
    required List<String> concepts,
    required String answer,
    required String slideText,
  }) async {
    if (!available) return null;
    try {
      return await (await _engineForTier()).judgeExplanation(concepts: concepts, answer: answer, slideText: slideText);
    } on ModelUnavailableException {
      await _dropEngine();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Finds the page behind a piece of material, or null if [notes] has no page markers.
  SourceLocator? _locatorFor(String notes) {
    final pages = parsePages(notes);
    return pages.isEmpty ? null : SourceLocator(pages);
  }

  Future<AiEngine> _engineForTier() async {
    final t = tier!;
    if (_engine == null || _engineTier != t.id) {
      await _dropEngine();
      _engine = engineFactory(t, models.fileFor(t));
      _engineTier = t.id;
    }
    return _engine!;
  }

  Future<void> acceptFallback() async {
    final t = fallbackOffer;
    if (t == null) return;
    fallbackOffer = null;
    error = null;
    await chooseTier(t);
  }

  /// Stops the model server. Call when the app is closing.
  Future<void> shutdown() => _dropEngine();

  Future<void> _dropEngine() async {
    await _engine?.dispose();
    _engine = null;
    _engineTier = null;
  }
}
