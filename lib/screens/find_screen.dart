import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/geo_utils.dart';
import '../models/enums.dart';
import '../models/proximity_state.dart';
import '../providers/app_state.dart';
import '../widgets/level_style.dart';
import '../widgets/proximity_gauge.dart';
import '../widgets/signal_chips.dart';

/// 약속 장소 찾기 모드. "뜨겁다/차갑다" 게이지 + GPS 방향 안내
class FindScreen extends StatelessWidget {
  const FindScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pair = state.pair!;
    final p = state.proximity;
    final textTheme = Theme.of(context).textTheme;
    final partnerName = pair.mode.roleLabel(pair.role.other);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          ProximityGauge(state: p, maxMeters: AppConstants.findGaugeMaxMeters),
          const SizedBox(height: 24),
          Text(
            _heat(p, state.running),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: p.level.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _hint(p, state.running, partnerName),
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (state.running) SignalChips(state: p),
          const SizedBox(height: 24),
          if (p.bearingDegrees != null) _DirectionCard(state: p),
          const SizedBox(height: 12),
          const _HowToCard(),
        ],
      ),
    );
  }

  String _heat(ProximityState p, bool running) {
    if (!running) return '추적을 시작해 주세요';
    final d = p.distanceMeters;
    if (d == null) return '아직 신호가 없어요';
    if (d <= AppConstants.nearThresholdMeters) return '🔥 바로 옆이에요!';
    if (d <= 10) return '뜨거워요';
    if (d <= 30) return '따뜻해요';
    if (d <= 100) return '차가워요';
    return '아직 멀어요';
  }

  String _hint(ProximityState p, bool running, String partner) {
    if (!running) return '약속 장소에 가까워지면 켜 두세요.';
    return switch (p.source) {
      DistanceSource.ble => '$partner 기기가 블루투스로 잡혀요. 주변을 둘러보세요!',
      DistanceSource.gps => 'GPS로 대략적인 거리와 방향을 알려드려요. '
          '30m 안으로 들어오면 블루투스로 바뀝니다.',
      DistanceSource.none => p.level == ProximityLevel.lost
          ? '신호가 끊겼어요. 상대 앱이 켜져 있는지 확인하세요.'
          : '상대 기기에서도 같은 코드로 추적을 시작해야 해요.',
    };
  }
}

class _DirectionCard extends StatelessWidget {
  const _DirectionCard({required this.state});

  final ProximityState state;

  @override
  Widget build(BuildContext context) {
    final bearing = state.bearingDegrees!;
    return Card(
      child: ListTile(
        leading: Transform.rotate(
          angle: bearing * 3.141592653589793 / 180,
          child: const Icon(Icons.navigation, size: 32),
        ),
        title: Text('${GeoUtils.bearingToKorean(bearing)}쪽 방향'),
        subtitle: Text(
          '방위 ${bearing.round()}° (지도의 북쪽 기준). '
          '화살표는 GPS 좌표로 계산한 방향이며 기기 방향과는 무관해요.',
        ),
      ),
    );
  }
}

class _HowToCard extends StatelessWidget {
  const _HowToCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('사용 팁', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• 멀리 있을 땐 GPS 방향을 따라 이동하세요.'),
            Text('• "따뜻해요"부터는 블루투스가 잡힌 것. 건물 안이라도 같은 층일 가능성이 높아요.'),
            Text('• "뜨거워요"면 10m 안. 고개를 들어 주변을 보세요.'),
            Text('• 벽·사람이 많으면 거리가 실제보다 멀게 나올 수 있어요.'),
          ],
        ),
      ),
    );
  }
}
