import 'package:flutter_test/flutter_test.dart';
import 'package:kid_guard/core/constants.dart';
import 'package:kid_guard/core/geo_utils.dart';
import 'package:kid_guard/core/pair_uuid.dart';
import 'package:kid_guard/models/enums.dart';

void main() {
  group('pairServiceUuid', () {
    test('코드와 역할이 UUID에 그대로 들어간다', () {
      expect(pairServiceUuid('123456', PairRole.host),
          '4b494447-5541-5244-0001-000000123456');
      expect(pairServiceUuid('123456', PairRole.guest),
          '4b494447-5541-5244-0002-000000123456');
    });

    test('host와 guest UUID는 서로 다르다', () {
      expect(pairServiceUuid('000001', PairRole.host),
          isNot(pairServiceUuid('000001', PairRole.guest)));
    });

    test('6자리가 아니면 예외', () {
      expect(() => pairServiceUuid('12345', PairRole.host),
          throwsArgumentError);
    });

    test('other는 역할을 뒤집는다', () {
      expect(PairRole.host.other, PairRole.guest);
      expect(PairRole.guest.other, PairRole.host);
    });
  });

  group('GeoUtils.distanceMeters', () {
    test('같은 점은 0', () {
      expect(GeoUtils.distanceMeters(37.5, 127.0, 37.5, 127.0), 0);
    });

    test('서울시청 → 광화문 약 1.07km', () {
      final d = GeoUtils.distanceMeters(37.5663, 126.9779, 37.5759, 126.9769);
      expect(d, closeTo(1070, 60));
    });

    test('위도 0.001도 ≈ 111m', () {
      final d = GeoUtils.distanceMeters(0, 0, 0.001, 0);
      expect(d, closeTo(111, 2));
    });
  });

  group('GeoUtils.bearing', () {
    test('정북은 0도', () {
      expect(GeoUtils.bearingDegrees(0, 0, 1, 0), closeTo(0, 0.01));
    });

    test('정동은 90도', () {
      expect(GeoUtils.bearingDegrees(0, 0, 0, 1), closeTo(90, 0.01));
    });

    test('8방위 한글 변환', () {
      expect(GeoUtils.bearingToKorean(0), '북');
      expect(GeoUtils.bearingToKorean(45), '북동');
      expect(GeoUtils.bearingToKorean(90), '동');
      expect(GeoUtils.bearingToKorean(180), '남');
      expect(GeoUtils.bearingToKorean(270), '서');
      expect(GeoUtils.bearingToKorean(359), '북');
    });
  });

  group('GeoUtils.rssiToMeters', () {
    test('기준 RSSI는 1m', () {
      expect(
        GeoUtils.rssiToMeters(AppConstants.rssiAtOneMeter.toDouble()),
        closeTo(1, 0.001),
      );
    });

    test('신호가 약해지면 거리가 늘어난다', () {
      final near = GeoUtils.rssiToMeters(-50);
      final far = GeoUtils.rssiToMeters(-80);
      expect(far, greaterThan(near));
    });
  });

  group('GeoUtils.formatDistance', () {
    test('단위 표기', () {
      expect(GeoUtils.formatDistance(0.5), '1m 이내');
      expect(GeoUtils.formatDistance(12.4), '약 12m');
      expect(GeoUtils.formatDistance(1500), '약 1.5km');
    });
  });
}
