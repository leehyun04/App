import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// 위치·블루투스·알림 권한 요청
class PermissionService {
  /// 필요한 권한을 모두 요청하고, 필수 권한이 허용됐는지 돌려준다.
  Future<bool> requestAll() async {
    final wanted = <Permission>[
      Permission.locationWhenInUse,
      Permission.notification,
    ];
    if (Platform.isAndroid) {
      wanted.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ]);
    } else if (Platform.isIOS) {
      wanted.add(Permission.bluetooth);
    }

    final statuses = await wanted.request();

    bool granted(Permission p) {
      final s = statuses[p];
      // 해당 OS 버전에서 존재하지 않는 권한은 null 또는 granted로 온다
      return s == null || s.isGranted || s.isLimited;
    }

    final required = <Permission>[
      Permission.locationWhenInUse,
      if (Platform.isAndroid) ...[
        Permission.bluetoothScan,
        Permission.bluetoothAdvertise,
      ],
      if (Platform.isIOS) Permission.bluetooth,
    ];
    return required.every(granted);
  }

  Future<bool> openSettings() => openAppSettings();
}
