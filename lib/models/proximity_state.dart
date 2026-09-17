import 'enums.dart';
import 'geo_fix.dart';

/// ProximityEngine이 매 순간 계산해 내는 결과 스냅샷
class ProximityState {
  const ProximityState({
    required this.level,
    this.distanceMeters,
    this.source = DistanceSource.none,
    this.rssi,
    this.bearingDegrees,
    this.lastBleSeen,
    this.partnerFix,
    this.gpsAccuracy,
  });

  static const ProximityState unknown =
      ProximityState(level: ProximityLevel.unknown);

  final ProximityLevel level;

  /// 추정 거리(m). 신호가 없으면 null
  final double? distanceMeters;
  final DistanceSource source;

  /// 최근 원시 RSSI(dBm). BLE 신호가 살아있을 때만
  final int? rssi;

  /// 내 위치 → 상대 위치 방위각(도). GPS가 둘 다 있을 때만
  final double? bearingDegrees;
  final DateTime? lastBleSeen;

  /// 상대의 마지막 GPS 위치 (지도 표시·마지막 위치 확인용)
  final GeoFix? partnerFix;

  /// 내 GPS 정확도 + 상대 GPS 정확도 (m). GPS 거리의 오차 범위
  final double? gpsAccuracy;

  bool get isBad =>
      level == ProximityLevel.far || level == ProximityLevel.lost;
}
