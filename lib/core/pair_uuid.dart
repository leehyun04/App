import '../models/enums.dart';
import 'constants.dart';

/// 페어 코드와 역할로 BLE 서비스 UUID를 만든다.
///
/// 코드 자체를 UUID에 넣기 때문에 상대 기기는 "정확히 이 UUID"만 스캔하면 된다.
/// 이 방식은 iOS 백그라운드 광고(서비스 UUID만 노출됨)에서도 동작한다.
///
/// 예) 코드 123456
///   host  → 4b494447-5541-5244-0001-000000123456
///   guest → 4b494447-5541-5244-0002-000000123456
String pairServiceUuid(String code, PairRole role) {
  final digits = code.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 6) {
    throw ArgumentError('페어 코드는 6자리 숫자여야 합니다: $code');
  }
  return '${AppConstants.uuidPrefix}-${role.uuidSegment}-${digits.padLeft(12, '0')}';
}
