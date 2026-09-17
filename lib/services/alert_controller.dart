import '../core/constants.dart';
import '../core/geo_utils.dart';
import '../models/enums.dart';
import '../models/proximity_state.dart';
import 'notification_service.dart';

/// ProximityState 변화를 보고 "언제 알림을 울릴지" 결정한다.
///
/// - 이탈 방지: far/lost가 일정 시간 지속되면 경고, 돌아오면 안심 알림
/// - 약속 찾기: 상대가 블루투스 범위에 들어오면·바로 옆이면 알림
class AlertController {
  AlertController(this._notifications);

  final NotificationService _notifications;

  DateTime? _badSince;
  ProximityLevel? _notifiedBad;
  bool _announcedNearby = false;
  bool _announcedNear = false;

  void reset() {
    _badSince = null;
    _notifiedBad = null;
    _announcedNearby = false;
    _announcedNear = false;
  }

  void handle(ProximityState s, AppMode mode) {
    switch (mode) {
      case AppMode.guard:
        _handleGuard(s);
      case AppMode.find:
        _handleFind(s);
    }
  }

  void _handleGuard(ProximityState s) {
    final now = DateTime.now();

    if (s.isBad) {
      _badSince ??= now;
      final sustained =
          now.difference(_badSince!) >= AppConstants.alertDebounce;
      if (sustained && _notifiedBad != s.level) {
        _notifiedBad = s.level;
        if (s.level == ProximityLevel.far) {
          final d = s.distanceMeters;
          _notifications.showAlert(
            '아이가 멀어졌어요',
            d == null
                ? '설정한 거리 밖으로 벗어났어요. 주변을 확인해 주세요.'
                : '${GeoUtils.formatDistance(d)} 떨어져 있어요. 주변을 확인해 주세요.',
          );
        } else {
          _notifications.showAlert(
            '아이 신호가 끊겼어요',
            '블루투스·GPS 모두 잡히지 않아요. 마지막 위치를 확인해 주세요.',
          );
        }
      }
      return;
    }

    _badSince = null;
    final safe =
        s.level == ProximityLevel.ok || s.level == ProximityLevel.near;
    if (_notifiedBad != null && safe) {
      _notifiedBad = null;
      _notifications.showInfo('다시 가까이 있어요', '아이가 안전 거리 안으로 돌아왔어요.');
    }
  }

  void _handleFind(ProximityState s) {
    if (s.source == DistanceSource.ble && !_announcedNearby) {
      _announcedNearby = true;
      _notifications.showInfo(
        '상대가 근처에 있어요',
        '블루투스 범위(약 30m) 안에 들어왔어요. 주변을 둘러보세요.',
      );
    }
    if (s.level == ProximityLevel.near && !_announcedNear) {
      _announcedNear = true;
      _notifications.showInfo('바로 옆에 있어요!', '몇 미터 이내예요.');
    }
    // 다시 멀어지면 다음 접근 때 또 알릴 수 있게 재무장
    if (s.level == ProximityLevel.lost || s.level == ProximityLevel.unknown) {
      _announcedNearby = false;
      _announcedNear = false;
    }
  }
}
