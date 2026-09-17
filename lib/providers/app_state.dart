import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';
import '../core/pair_uuid.dart';
import '../models/enums.dart';
import '../models/geo_fix.dart';
import '../models/pair_info.dart';
import '../models/proximity_state.dart';
import '../services/alert_controller.dart';
import '../services/ble_service.dart';
import '../services/location_service.dart';
import '../services/location_sync_service.dart';
import '../services/notification_service.dart';
import '../services/pairing_service.dart';
import '../services/permission_service.dart';
import '../services/proximity_engine.dart';

/// 앱 전체 상태와 서비스 오케스트레이션.
///
/// 페어링 → 추적 시작(BLE 광고/스캔 + GPS + 서버 동기화) → 엔진 판정 → 알림
class AppState extends ChangeNotifier {
  AppState({
    required PairingService pairing,
    required BleService ble,
    required LocationService location,
    required LocationSyncService sync,
    required NotificationService notifications,
    required PermissionService permissions,
  })  : _pairing = pairing,
        _ble = ble,
        _location = location,
        _sync = sync,
        _permissions = permissions,
        alerts = AlertController(notifications) {
    engine.addListener(_onEngineChanged);
  }

  final PairingService _pairing;
  final BleService _ble;
  final LocationService _location;
  final LocationSyncService _sync;
  final PermissionService _permissions;

  final ProximityEngine engine = ProximityEngine();
  final AlertController alerts;

  PairInfo? _pair;
  PairInfo? get pair => _pair;

  bool _running = false;
  bool get running => _running;

  String? _error;
  String? get error => _error;

  GeoFix? _lastOwnFix;
  GeoFix? get ownFix => _lastOwnFix;

  bool get syncAvailable => _sync.isAvailable;
  ProximityState get proximity => engine.state;

  StreamSubscription<int>? _rssiSub;
  StreamSubscription<Position>? _posSub;
  StreamSubscription<GeoFix?>? _partnerSub;
  Timer? _publishTimer;

  Future<void> init() async {
    _pair = await _pairing.load();
    final p = _pair;
    if (p != null) engine.alertRadius = p.alertRadius;
    notifyListeners();
  }

  // ---------- 페어링 ----------

  /// 새 코드를 만들어 host로 페어링. 코드를 반환한다.
  Future<String> createPair(AppMode mode) async {
    final code = _pairing.generateCode();
    await _setPair(PairInfo(
      code: code,
      role: PairRole.host,
      mode: mode,
      alertRadius: AppConstants.defaultAlertRadiusMeters,
    ));
    return code;
  }

  /// 상대가 만든 코드로 guest 참여
  Future<bool> joinPair(String code, AppMode mode) async {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 6) {
      _setError('6자리 숫자 코드를 입력해 주세요.');
      return false;
    }
    await _setPair(PairInfo(
      code: digits,
      role: PairRole.guest,
      mode: mode,
      alertRadius: AppConstants.defaultAlertRadiusMeters,
    ));
    return true;
  }

  Future<void> _setPair(PairInfo info) async {
    await stopTracking();
    _pair = info;
    engine.alertRadius = info.alertRadius;
    await _pairing.save(info);
    _error = null;
    notifyListeners();
  }

  Future<void> updatePair({AppMode? mode, double? alertRadius}) async {
    final current = _pair;
    if (current == null) return;
    final updated = current.copyWith(mode: mode, alertRadius: alertRadius);
    _pair = updated;
    engine.alertRadius = updated.alertRadius;
    alerts.reset();
    await _pairing.save(updated);
    notifyListeners();
  }

  Future<void> unpair() async {
    await stopTracking();
    _pair = null;
    await _pairing.clear();
    engine.reset();
    alerts.reset();
    notifyListeners();
  }

  // ---------- 추적 ----------

  Future<bool> startTracking() async {
    final pair = _pair;
    if (pair == null) return false;
    if (_running) return true;
    _error = null;

    if (!await _permissions.requestAll()) {
      _setError('위치·블루투스·알림 권한이 필요합니다. 설정에서 허용해 주세요.');
      return false;
    }
    if (!await _location.isServiceEnabled()) {
      _setError('위치 서비스(GPS)를 켜 주세요.');
      return false;
    }
    if (!await _ble.isReady()) {
      _setError('블루투스를 켜 주세요.');
      return false;
    }

    engine.reset();
    alerts.reset();

    try {
      await _ble.start(
        advertiseUuid: pairServiceUuid(pair.code, pair.role),
        scanUuid: pairServiceUuid(pair.code, pair.role.other),
      );
    } catch (e) {
      _setError('블루투스 시작 실패: $e');
      return false;
    }

    _rssiSub = _ble.rssiStream.listen(engine.onRssi);

    // 첫 위치를 빨리 얻기 위해 1회 조회 후 스트림 구독
    final first = await _location.current();
    if (first != null) _handleOwnPosition(first);
    _posSub = _location.watch().listen(
          _handleOwnPosition,
          onError: (Object e) => _setError('위치 오류: $e'),
        );

    _partnerSub = _sync.watchPartner(pair.code, pair.role.other).listen(
          engine.onPartnerFix,
          onError: (Object e) => debugPrint('[sync] watch error: $e'),
        );

    _publishTimer = Timer.periodic(
      AppConstants.locationPublishInterval,
      (_) => _publishOwnLocation(),
    );

    engine.start();
    _running = true;
    notifyListeners();
    return true;
  }

  Future<void> stopTracking() async {
    if (!_running) return;
    _running = false;
    engine.stop();
    _publishTimer?.cancel();
    _publishTimer = null;
    await _rssiSub?.cancel();
    await _posSub?.cancel();
    await _partnerSub?.cancel();
    _rssiSub = null;
    _posSub = null;
    _partnerSub = null;
    await _ble.stop();
    notifyListeners();
  }

  void _handleOwnPosition(Position p) {
    final fix = GeoFix.fromPosition(p);
    _lastOwnFix = fix;
    engine.onOwnFix(fix);
  }

  /// 마지막 위치를 현재 시각으로 찍어 올린다 (가만히 있어도 하트비트가 유지됨)
  Future<void> _publishOwnLocation() async {
    final pair = _pair;
    final fix = _lastOwnFix;
    if (pair == null || fix == null || !_sync.isAvailable) return;
    try {
      await _sync.publish(
          pair.code, pair.role, fix.copyWith(timestamp: DateTime.now()));
    } catch (e) {
      debugPrint('[sync] publish error: $e');
    }
  }

  void _onEngineChanged() {
    final pair = _pair;
    if (pair != null && _running) {
      alerts.handle(engine.state, pair.mode);
    }
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    engine.removeListener(_onEngineChanged);
    stopTracking();
    engine.dispose();
    _ble.dispose();
    super.dispose();
  }
}
