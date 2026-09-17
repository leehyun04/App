import 'package:geolocator/geolocator.dart';

import '../core/constants.dart';

/// 내 기기의 GPS 위치 스트림
class LocationService {
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  /// 고정밀 위치 스트림. 설정한 거리 이상 움직였을 때만 갱신된다.
  Stream<Position> watch() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: AppConstants.locationDistanceFilterMeters,
    );
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  /// 현재 위치 1회 조회 (시작 직후 첫 위치를 빨리 얻기 위함)
  Future<Position?> current() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }
}
