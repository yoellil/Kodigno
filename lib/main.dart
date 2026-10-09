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
import 'ui/home_screen.dart';
import 'ui/kulay.dart';
import 'ui/library_screen.dart';
import 'ui/loaders.dart';
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

class _KodignoAppState extends State<KodignoApp> with WidgetsBindingObserver {
  final _tab = ValueNotifier(0);
  var _stage = _Stage.home; // landing screen first

  void _go(_Stage s) => setState(() => _stage = s);
  late final AppLifecycleListener _lifecycle;

  @override
  void didChangePlatformBrightness() => setState(() {}); // "System" theme follows the OS

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Stop the bundled model server when the window closes.
    _lifecycle = AppLifecycleListener(onExitRequested: () async {
      await context.read<AppController>().shutdown();
      return AppExitResponse.exit;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycle.dispose();
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<AppController>();
    final ready = c.modelReady;
    K.dark = c.themeMode == ThemeMode.dark ||
        (c.themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
    return MaterialApp(
      key: ValueKey(K.dark), // K's colors are read at build time: rebuild the whole tree on a flip
      title: 'Kodigno',
      debugShowCheckedModeBanner: false,
      theme: kTheme(),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 550),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(anim), child: child),
        ),
        child: KeyedSubtree(key: ValueKey((_stage, ready)), child: _page(ready)),
      ),
    );
  }

  Widget _page(bool ready) => switch (_stage) {
        _Stage.home => HomeScreen(onOpen: () => _go(_Stage.kodignoLoading)),
        _Stage.kodignoLoading => LoadingScreen(
            art: LoaderArt.folder,
            label: 'Opening Kodigno',
            onDone: () => _go(_Stage.kodigno),
          ),
        _Stage.kodigno => ready
            ? AppShell(
                tab: _tab,
                onHome: () => _go(_Stage.home),
                onKulay: () => _go(_Stage.kulayLoading),
                pages: [
                  LibraryScreen(repo: widget.repo, tab: _tab),
                  AddSourceScreen(repo: widget.repo, reader: widget.reader),
                  const SettingsScreen(),
                ],
              )
            : SetupScreen(onBack: () => _go(_Stage.home)),
        _Stage.kulayLoading => LoadingScreen(
            art: LoaderArt.eye,
            label: 'Opening Kulay',
            onDone: () => _go(_Stage.kulay),
          ),
        _Stage.kulay => KulayScreen(onBack: () => _go(_Stage.kodigno)),
      };
}

/// Landing, then the loader, then the app; Kulay opens full screen from it.
enum _Stage { home, kodignoLoading, kodigno, kulayLoading, kulay }
