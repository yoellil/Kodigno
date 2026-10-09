import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/ai_engine.dart';
import 'ai/llm_ai_engine.dart';
import 'data/repository.dart';
import 'domain/models.dart';
import 'domain/summary.dart';
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

class AppController extends ChangeNotifier {
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
    themeMode = ThemeMode.values.asNameMap()[prefs.getString('theme')] ?? ThemeMode.system;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    themeMode = m;
    await prefs.setString('theme', m.name);
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
      return await repo.saveSet(title, set,
          sourceType: sourceType,
          sourceText: notes,
          sourcePaths: sourcePaths,
          summary: lesson);
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
      return await (await _engineForTier()).summarize(notes, onProgress: (f) {
        summaryFraction = f;
        notifyListeners();
      });
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
