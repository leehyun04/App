import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../models/proximity_state.dart';

/// 신호 종류·RSSI·마지막 감지 시각을 칩으로 나열
class SignalChips extends StatelessWidget {
  const SignalChips({super.key, required this.state});

  final ProximityState state;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      Chip(
        avatar: Icon(
          state.source == DistanceSource.ble
              ? Icons.bluetooth
              : state.source == DistanceSource.gps
                  ? Icons.gps_fixed
                  : Icons.signal_cellular_off,
          size: 18,
        ),
        label: Text(state.source.label),
      ),
    ];

    final rssi = state.rssi;
    if (rssi != null) {
      chips.add(Chip(label: Text('RSSI $rssi dBm')));
    }

    final acc = state.gpsAccuracy;
    if (state.source == DistanceSource.gps && acc != null) {
      chips.add(Chip(label: Text('GPS 오차 ±${acc.round()}m')));
    }

    final seen = state.lastBleSeen;
    if (seen != null) {
      final ago = DateTime.now().difference(seen).inSeconds;
      chips.add(Chip(
        avatar: const Icon(Icons.schedule, size: 18),
        label: Text(ago < 2 ? '지금 감지' : '$ago초 전 블루투스 감지'),
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }
}
