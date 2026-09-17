import 'enums.dart';

/// 로컬에 저장되는 페어링 정보
class PairInfo {
  const PairInfo({
    required this.code,
    required this.role,
    required this.mode,
    required this.alertRadius,
  });

  /// 6자리 숫자 코드. 두 기기가 같은 코드를 가진다.
  final String code;
  final PairRole role;
  final AppMode mode;

  /// 이탈 방지 경고 거리(m)
  final double alertRadius;

  PairInfo copyWith({AppMode? mode, double? alertRadius}) => PairInfo(
        code: code,
        role: role,
        mode: mode ?? this.mode,
        alertRadius: alertRadius ?? this.alertRadius,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'role': role.name,
        'mode': mode.name,
        'alertRadius': alertRadius,
      };

  factory PairInfo.fromJson(Map<String, dynamic> json) => PairInfo(
        code: json['code'] as String,
        role: PairRole.values.byName(json['role'] as String),
        mode: AppMode.values.byName(json['mode'] as String),
        alertRadius: (json['alertRadius'] as num).toDouble(),
      );
}
