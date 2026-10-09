import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai/llama_server_runtime.dart';
import 'ai/llm_ai_engine.dart';
import 'app_controller.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'models/device_profiler.dart';
import 'models/model_downloader.dart';
import 'models/model_manager.dart';
import 'models/tier.dart';
import 'ocr/ocr_service.dart';
import 'sources/pdf_text.dart';
import 'sources/source_reader.dart';
import 'ui/add_source_screen.dart';
import 'ui/app_shell.dart';
import 'ui/library_screen.dart';
import 'ui/model_setup.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize(); // required before using the PDF document API directly
  final support = await getApplicationSupportDirectory();
  final modelsDir = Directory(p.join(support.path, 'models'))..createSync(recursive: true);
  final tiers = TierTable.fromJson(await rootBundle.loadString('assets/model_tiers.json'));
  final repo = StudyRepository(AppDatabase(driftDatabase(name: 'kodigno')));

  final controller = AppController(
    tiers: tiers,
    profiler: WindowsDeviceProfiler(modelsDir),
    models: ModelManager(modelsDir, ModelDownloader()),
    repo: repo,
    engineFactory: (tier, file) => LlmAiEngine(LlamaServerRuntime.bundled(file.path), tier),
    prefs: await SharedPreferences.getInstance(),
  );
  await controller.init();

  final reader = SourceReader(ocr: TesseractCliOcr.bundled(), pdf: PdfrxTextExtractor());
  runApp(ChangeNotifierProvider.value(
    value: controller,
    child: KodignoApp(repo: repo, reader: reader),
  ));
}

class KodignoApp extends StatefulWidget {
  const KodignoApp({super.key, required this.repo, required this.reader});
  final StudyRepository repo;
  final SourceReader reader;

  @override
  State<KodignoApp> createState() => _KodignoAppState();
}

class _KodignoAppState extends State<KodignoApp> {
  final _tab = ValueNotifier(0);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Stop the bundled model server when the window closes.
    _lifecycle = AppLifecycleListener(onExitRequested: () async {
      await context.read<AppController>().shutdown();
      return AppExitResponse.exit;
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = context.watch<AppController>().modelReady;
    return MaterialApp(
      title: 'Kodigno',
      debugShowCheckedModeBanner: false,
      theme: kTheme(),
      home: ready
          ? AppShell(
              tab: _tab,
              pages: [
                LibraryScreen(repo: widget.repo, tab: _tab),
                AddSourceScreen(repo: widget.repo, reader: widget.reader),
                const SettingsScreen(),
              ],
            )
          : const SetupScreen(),
    );
  }
}
