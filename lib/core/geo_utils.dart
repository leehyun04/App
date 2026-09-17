import 'dart:math' as math;

import 'constants.dart';

/// 거리·방위·RSSI 변환 유틸.
class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusMeters = 6371000;

  static double _toRad(double deg) => deg * math.pi / 180;
  static double _toDeg(double rad) => rad * 180 / math.pi;

  /// 두 좌표 사이 거리(m). Haversine 공식.
  static double distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return _earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// 1 → 2 방향의 방위각(도, 0=북, 시계방향).
  static double bearingDegrees(
      double lat1, double lng1, double lat2, double lng2) {
    final phi1 = _toRad(lat1);
    final phi2 = _toRad(lat2);
    final dLng = _toRad(lng2 - lng1);
    final y = math.sin(dLng) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLng);
    return (_toDeg(math.atan2(y, x)) + 360) % 360;
  }

  /// 방위각 → 8방위 한글 (북, 북동, ...).
  static String bearingToKorean(double deg) {
    const names = ['북', '북동', '동', '남동', '남', '남서', '서', '북서'];
    final index = ((deg + 22.5) % 360) ~/ 45;
    return names[index];
  }

  /// RSSI(dBm) → 대략적인 거리(m). 로그 거리 경로 손실 모델.
  static double rssiToMeters(double rssi) {
    final exponent = (AppConstants.rssiAtOneMeter - rssi) /
        (10 * AppConstants.pathLossExponent);
    return math.pow(10, exponent).toDouble();
  }

  static String formatDistance(double meters) {
    if (meters < 1) return '1m 이내';
    if (meters < 1000) return '약 ${meters.round()}m';
    return '약 ${(meters / 1000).toStringAsFixed(1)}km';
  }
}
