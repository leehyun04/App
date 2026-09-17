import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_state.dart';
import 'services/ble_service.dart';
import 'services/location_service.dart';
import 'services/location_sync_service.dart';
import 'services/notification_service.dart';
import 'services/pairing_service.dart';
import 'services/permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sync = await _initLocationSync();

  final notifications = NotificationService();
  await notifications.init();

  final appState = AppState(
    pairing: PairingService(),
    ble: BleService(),
    location: LocationService(),
    sync: sync,
    notifications: notifications,
    permissions: PermissionService(),
  );
  await appState.init();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const KidGuardApp(),
    ),
  );
}

/// Firebase가 설정돼 있으면 Firestore 동기화, 아니면 블루투스 전용으로 동작.
///
/// Firebase 설정 방법은 README 참고. `flutterfire configure` 실행 후
/// 생성된 firebase_options.dart를 import하고 아래처럼 바꾸면 된다:
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
Future<LocationSyncService> _initLocationSync() async {
  try {
    await Firebase.initializeApp();
    debugPrint('[init] Firebase 연결됨 → GPS 동기화 사용');
    return FirestoreLocationSync();
  } catch (e) {
    debugPrint('[init] Firebase 미설정 → 블루투스 전용 모드 ($e)');
    return NoopLocationSync();
  }
}
