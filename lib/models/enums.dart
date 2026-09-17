/// 페어 안에서의 역할. 코드를 만든 쪽이 host, 입력해 참여한 쪽이 guest.
enum PairRole { host, guest }

extension PairRoleX on PairRole {
  PairRole get other => this == PairRole.host ? PairRole.guest : PairRole.host;

  /// BLE UUID 4번째 그룹에 들어가는 역할 식별자
  String get uuidSegment => this == PairRole.host ? '0001' : '0002';
}

/// 앱 동작 모드
enum AppMode { guard, find }

extension AppModeX on AppMode {
  String get label => switch (this) {
        AppMode.guard => '이탈 방지',
        AppMode.find => '약속 장소 찾기',
      };

  String get description => switch (this) {
        AppMode.guard => '아이가 설정한 거리보다 멀어지면 즉시 경고합니다.',
        AppMode.find => '약속 장소 근처에서 서로 가까워지면 알려줍니다.',
      };

  String get hostLabel => switch (this) {
        AppMode.guard => '보호자',
        AppMode.find => '약속 주최자',
      };

  String get guestLabel => switch (this) {
        AppMode.guard => '아이',
        AppMode.find => '참여자',
      };

  String roleLabel(PairRole role) =>
      role == PairRole.host ? hostLabel : guestLabel;
}

/// 근접 판정 결과
enum ProximityLevel {
  /// 아직 상대를 한 번도 감지하지 못함
  unknown,

  /// 몇 m 이내
  near,

  /// 경고 거리 안
  ok,

  /// 경고 거리 밖
  far,

  /// 감지했던 상대의 신호가 끊김
  lost,
}

/// 거리 계산에 사용된 신호 종류
enum DistanceSource { none, ble, gps }

extension DistanceSourceX on DistanceSource {
  String get label => switch (this) {
        DistanceSource.none => '신호 없음',
        DistanceSource.ble => '블루투스',
        DistanceSource.gps => 'GPS',
      };
}
