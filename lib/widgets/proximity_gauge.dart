import 'package:flutter/material.dart';

import '../core/geo_utils.dart';
import '../models/enums.dart';
import '../models/proximity_state.dart';
import 'level_style.dart';

/// 가까울수록 꽉 차는 원형 게이지. 중앙에 거리와 신호 종류 표시.
class ProximityGauge extends StatelessWidget {
  const ProximityGauge({
    super.key,
    required this.state,
    required this.maxMeters,
    this.size = 220,
  });

  final ProximityState state;

  /// 이 거리 이상이면 게이지가 비어 보인다
  final double maxMeters;
  final double size;

  @override
  Widget build(BuildContext context) {
    final d = state.distanceMeters;
    final closeness =
        d == null ? 0.0 : (1 - d / maxMeters).clamp(0.05, 1.0).toDouble();
    final color = state.level.color;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: closeness),
              duration: const Duration(milliseconds: 500),
              builder: (_, value, __) => CircularProgressIndicator(
                value: value,
                strokeWidth: 16,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(state.level.icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                d == null ? '--' : GeoUtils.formatDistance(d),
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                state.source == DistanceSource.none
                    ? ''
                    : '${state.source.label} 기준',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
