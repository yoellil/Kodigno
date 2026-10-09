import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceProfile {
  const DeviceProfile({required this.ramMb, required this.freeStorageMb});
  final int ramMb;
  final int freeStorageMb;
}

abstract class DeviceProfiler {
  Future<DeviceProfile> read();
}

class WindowsDeviceProfiler implements DeviceProfiler {
  WindowsDeviceProfiler(this.modelsDir);
  final Directory modelsDir;

  /// Used when free space cannot be read, so a failed probe never blocks setup.
  static const unknownStorageMb = 1000000;

  @override
  Future<DeviceProfile> read() async {
    final info = await DeviceInfoPlugin().windowsInfo;
    final letter = modelsDir.path[0];
    var freeMb = unknownStorageMb;
    try {
      final r = await Process.run('powershell',
          ['-NoProfile', '-Command', '(Get-PSDrive -Name $letter).Free']);
      final bytes = int.tryParse(r.stdout.toString().trim());
      if (bytes != null) freeMb = bytes ~/ (1024 * 1024);
    } on ProcessException {
      // keep unknownStorageMb
    }
    return DeviceProfile(ramMb: info.systemMemoryInMegabytes, freeStorageMb: freeMb);
  }
}
