import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/geo_utils.dart';
import '../models/enums.dart';
import '../models/geo_fix.dart';
import '../models/proximity_state.dart';

/// 블루투스 RSSI와 GPS 좌표를 합쳐 "상대와 얼마나 떨어져 있나"를 판정한다.
///
/// 우선순위:
///  1. BLE 신호가 살아있으면 → RSSI 기반 거리 (근거리·실내에서 정확)
///  2. BLE가 끊겼고 양쪽 GPS가 있으면 → 좌표 거리 (원거리·실외)
///  3. 둘 다 없으면 → lost (한 번이라도 봤다면) / unknown (처음부터 못 봄)
class ProximityEngine extends ChangeNotifier {
  ProximityEngine({double alertRadius = AppConstants.defaultAlertRadiusMeters})
      : _alertRadius = alertRadius;

  double _alertRadius;
  double get alertRadius => _alertRadius;
  set alertRadius(double value) {
    _alertRadius = value;
    _evaluate();
  }

  double? _smoothedRssi;
  int? _lastRawRssi;
  DateTime? _lastBleSeen;
  GeoFix? _ownFix;
  GeoFix? _partnerFix;
  Timer? _ticker;

  ProximityState _state = ProximityState.unknown;
  ProximityState get state => _state;

  /// 1초마다 재평가 (신호가 끊긴 것을 시간 경과로 감지하기 위함)
  void start() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _evaluate());
  }

  void stop() {
    _ticker?.cancel();
    _ticker = null;
  }

  void reset() {
    _smoothedRssi = null;
    _lastRawRssi = null;
    _lastBleSeen = null;
    _ownFix = null;
    _partnerFix = null;
    _state = ProximityState.unknown;
    notifyListeners();
  }

  /// BLE 스캔에서 상대 신호가 잡힐 때마다 호출
  void onRssi(int rssi) {
    _lastRawRssi = rssi;
    final prev = _smoothedRssi;
    _smoothedRssi = prev == null
        ? rssi.toDouble()
        : prev * (1 - AppConstants.rssiSmoothing) +
            rssi * AppConstants.rssiSmoothing;
    _lastBleSeen = DateTime.now();
    _evaluate();
  }

  void onOwnFix(GeoFix fix) {
    _ownFix = fix;
    _evaluate();
  }

  void onPartnerFix(GeoFix? fix) {
    _partnerFix = fix;
    _evaluate();
  }

  void _evaluate() {
    final now = DateTime.now();
    final lastBle = _lastBleSeen;
    final bleFresh =
        lastBle != null && now.difference(lastBle) < AppConstants.bleLostTimeout;
    if (!bleFresh) {
      // 오래된 평균값이 다음 접촉 때 거리를 왜곡하지 않도록 초기화
      _smoothedRssi = null;
    }

    final own = _ownFix;
    final partner = _partnerFix;
    // 내 위치는 가만히 서 있으면 갱신되지 않으므로 신선도를 따지지 않는다.
    // 상대 위치는 하트비트로 주기 갱신되므로 오래됐다면 상대 앱이 죽은 것.
    final gpsFresh = own != null &&
        partner != null &&
        now.difference(partner.timestamp) < AppConstants.gpsStaleTimeout;

    double? distance;
    var source = DistanceSource.none;
    double? bearing;
    double? gpsAccuracy;

    if (gpsFresh) {
      bearing = GeoUtils.bearingDegrees(
          own.latitude, own.longitude, partner.latitude, partner.longitude);
      gpsAccuracy = own.accuracy + partner.accuracy;
    }

    final rssi = _smoothedRssi;
    if (bleFresh && rssi != null) {
      distance = GeoUtils.rssiToMeters(rssi);
      source = DistanceSource.ble;
    } else if (gpsFresh) {
      distance = GeoUtils.distanceMeters(
          own.latitude, own.longitude, partner.latitude, partner.longitude);
      source = DistanceSource.gps;
    }

    final ProximityLevel level;
    if (distance == null) {
      level = (lastBle == null && partner == null)
          ? ProximityLevel.unknown
          : ProximityLevel.lost;
    } else if (distance <= AppConstants.nearThresholdMeters) {
      level = ProximityLevel.near;
    } else if (distance <= _alertRadius) {
      level = ProximityLevel.ok;
    } else {
      level = ProximityLevel.far;
    }

    _state = ProximityState(
      level: level,
      distanceMeters: distance,
      source: source,
      rssi: bleFresh ? _lastRawRssi : null,
      bearingDegrees: bearing,
      lastBleSeen: lastBle,
      partnerFix: partner,
      gpsAccuracy: gpsAccuracy,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
