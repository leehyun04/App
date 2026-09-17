import 'package:flutter/material.dart';

import '../models/enums.dart';

/// 근접 단계별 색상·아이콘
extension ProximityLevelStyle on ProximityLevel {
  Color get color => switch (this) {
        ProximityLevel.near => const Color(0xFF2E7D32),
        ProximityLevel.ok => const Color(0xFF1976D2),
        ProximityLevel.far => const Color(0xFFEF6C00),
        ProximityLevel.lost => const Color(0xFFC62828),
        ProximityLevel.unknown => const Color(0xFF757575),
      };

  IconData get icon => switch (this) {
        ProximityLevel.near => Icons.favorite,
        ProximityLevel.ok => Icons.check_circle,
        ProximityLevel.far => Icons.warning_amber_rounded,
        ProximityLevel.lost => Icons.bluetooth_disabled,
        ProximityLevel.unknown => Icons.radar,
      };
}
