import 'package:geolocator/geolocator.dart';

/// 한 시점의 GPS 위치. 내 위치와 상대 위치 모두 이 타입을 쓴다.
class GeoFix {
  const GeoFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;

  /// 수평 정확도(m)
  final double accuracy;
  final DateTime timestamp;

  factory GeoFix.fromPosition(Position p) => GeoFix(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        timestamp: p.timestamp,
      );

  GeoFix copyWith({DateTime? timestamp}) => GeoFix(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        timestamp: timestamp ?? this.timestamp,
      );

  /// Firestore 등 서버 저장용. 타임스탬프는 epoch ms 정수.
  Map<String, dynamic> toMap() => {
        'lat': latitude,
        'lng': longitude,
        'acc': accuracy,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  factory GeoFix.fromMap(Map<String, dynamic> m) => GeoFix(
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lng'] as num).toDouble(),
        accuracy: (m['acc'] as num?)?.toDouble() ?? 0,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch((m['ts'] as num).toInt()),
      );
}
