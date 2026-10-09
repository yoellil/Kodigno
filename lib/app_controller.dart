import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/ai_engine.dart';
import 'data/repository.dart';
import 'models/device_profiler.dart';
import 'models/model_manager.dart';
import 'models/tier.dart';

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
  String? error;
  Tier? fallbackOffer;
  bool storageTooLow = false;

  DeviceProfile? _device;
  AiEngine? _engine;
  String? _engineTier;

  Future<void> init() async {
    _device = await profiler.read();
    final saved = prefs.getString('tier');
    tier = saved != null ? tiers.byId(saved) : tiers.pick(_device!.ramMb);
    modelReady = await models.isInstalled(tier!);
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
      final t = tier!;
      if (_engine == null || _engineTier != t.id) {
        await _dropEngine();
        _engine = engineFactory(t, models.fileFor(t));
        _engineTier = t.id;
      }
      final set = await _engine!.generate(notes, onProgress: (f) {
        generationFraction = f;
        notifyListeners();
      });
      return await repo.saveSet(title, set,
          sourceType: sourceType, sourceText: notes, sourcePaths: sourcePaths);
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
