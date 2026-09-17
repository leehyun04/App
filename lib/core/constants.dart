/// 앱 전역 상수. 거리·시간 임계값은 실제 기기 테스트 후 조정하세요.
class AppConstants {
  AppConstants._();

  static const String appName = '아이지킴이';

  /// BLE 서비스 UUID 접두어. "KIDG-UARD"의 ASCII 16진수.
  /// 전체 UUID = 접두어 + 역할(0001/0002) + 6자리 페어 코드
  static const String uuidPrefix = '4b494447-5541-5244';

  // ---- 거리 임계값 (미터) ----
  /// 이탈 방지 모드 기본 경고 거리
  static const double defaultAlertRadiusMeters = 20;

  /// "바로 옆" 판정 거리
  static const double nearThresholdMeters = 3;

  /// 약속 찾기 모드 게이지 최대 거리
  static const double findGaugeMaxMeters = 50;

  // ---- 시간 임계값 ----
  /// 이 시간 동안 BLE 신호가 없으면 "끊김"으로 간주
  static const Duration bleLostTimeout = Duration(seconds: 12);

  /// 상대 GPS 위치가 이 시간보다 오래되면 무시
  static const Duration gpsStaleTimeout = Duration(seconds: 45);

  /// 이탈/끊김 상태가 이 시간 이상 지속돼야 알림 (오탐 방지)
  static const Duration alertDebounce = Duration(seconds: 6);

  /// 내 위치를 서버에 올리는 주기 (하트비트 겸용)
  static const Duration locationPublishInterval = Duration(seconds: 8);

  // ---- BLE 거리 추정 파라미터 ----
  /// 1m 거리에서의 기준 RSSI (기기별로 -55 ~ -65 사이, 실측 후 보정)
  static const int rssiAtOneMeter = -59;

  /// 경로 손실 지수. 실외 2.0, 실내 2.5~3.5
  static const double pathLossExponent = 2.5;

  /// RSSI 지수 이동평균 가중치 (0~1, 클수록 반응 빠르고 튐)
  static const double rssiSmoothing = 0.3;

  // ---- GPS ----
  /// 이 거리(m) 이상 움직였을 때만 위치 스트림이 갱신됨
  static const int locationDistanceFilterMeters = 3;
}
