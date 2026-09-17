import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/geo_utils.dart';
import '../models/enums.dart';
import '../models/proximity_state.dart';
import '../providers/app_state.dart';
import '../widgets/level_style.dart';
import '../widgets/proximity_gauge.dart';
import '../widgets/signal_chips.dart';

/// 이탈 방지 모드 메인 화면
class GuardScreen extends StatelessWidget {
  const GuardScreen({super.key});

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
          ProximityGauge(state: p, maxMeters: pair.alertRadius * 1.5),
          const SizedBox(height: 24),
          Text(
            _title(p, state.running, partnerName),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: p.level.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle(p, state.running, pair.alertRadius),
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (state.running) SignalChips(state: p),
          const SizedBox(height: 24),
          _RadiusInfo(alertRadius: pair.alertRadius),
          if (p.partnerFix != null) ...[
            const SizedBox(height: 12),
            _LastLocationCard(state: p, partnerName: partnerName),
          ],
        ],
      ),
    );
  }

  String _title(ProximityState p, bool running, String partner) {
    if (!running) return '추적을 시작해 주세요';
    return switch (p.level) {
      ProximityLevel.unknown => '$partner 기기를 찾는 중…',
      ProximityLevel.near => '$partner가 바로 옆에 있어요',
      ProximityLevel.ok => '안전 거리 안에 있어요',
      ProximityLevel.far => '설정 거리보다 멀어졌어요!',
      ProximityLevel.lost => '신호가 끊겼어요!',
    };
  }

  String _subtitle(ProximityState p, bool running, double radius) {
    if (!running) return '아래 버튼을 누르면 블루투스와 GPS로 감지를 시작합니다.';
    return switch (p.level) {
      ProximityLevel.unknown =>
        '상대 기기에서도 추적을 시작했는지 확인하세요. 같은 코드여야 해요.',
      ProximityLevel.near => '손 닿을 거리예요.',
      ProximityLevel.ok => '경고 거리 ${radius.round()}m 안에서 감지되고 있어요.',
      ProximityLevel.far => '즉시 주변을 확인해 주세요.',
      ProximityLevel.lost =>
        '블루투스 범위를 벗어났고 GPS 위치도 받지 못하고 있어요.',
    };
  }
}

class _RadiusInfo extends StatelessWidget {
  const _RadiusInfo({required this.alertRadius});

  final double alertRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.social_distance),
        title: Text('경고 거리 ${alertRadius.round()}m'),
        subtitle: const Text('이 거리보다 멀어지면 경고합니다. 설정에서 바꿀 수 있어요.'),
      ),
    );
  }
}

class _LastLocationCard extends StatelessWidget {
  const _LastLocationCard({required this.state, required this.partnerName});

  final ProximityState state;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final fix = state.partnerFix!;
    final ago = DateTime.now().difference(fix.timestamp).inSeconds;
    final bearing = state.bearingDegrees;
    final direction =
        bearing == null ? '' : ' · ${GeoUtils.bearingToKorean(bearing)}쪽';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text('$partnerName 마지막 GPS 위치$direction'),
        subtitle: Text(
          '${fix.latitude.toStringAsFixed(5)}, ${fix.longitude.toStringAsFixed(5)}'
          '  (±${fix.accuracy.round()}m, $ago초 전)',
        ),
      ),
    );
  }
}
