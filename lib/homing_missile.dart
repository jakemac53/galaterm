import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'projectile.dart';
import 'constants.dart';

class HomingMissile extends Projectile {
  Entity? _target;
  final int speedLevel;

  HomingMissile({
    required super.x,
    required super.y,
    required this.speedLevel,
    required super.damage,
  }) : super(
         dx: 0,
         dy: perFrame(-8.0 - speedLevel * 2),
         color: const Color(0xFFFF69B4), // Hot pink
         character: '^',
       );

  @override
  void move(GameState state) {
    bool targetExists = false;
    if (_target != null && _target!.health > 0) {
      for (final group in state.entities) {
        if (group.activeEntities.contains(_target)) {
          targetExists = true;
          break;
        }
      }
    }

    if (!targetExists) {
      // Find nearest enemy
      double nearestDist = double.infinity;
      _target = null;
      for (final group in state.entities) {
        for (final e in group.activeEntities) {
          if (e.isEnemy && e is! Projectile && e.health > 0) {
            final dist = sqrt(pow(e.x - x, 2) + pow(e.y - y, 2));
            if (dist < nearestDist) {
              nearestDist = dist;
              _target = e;
            }
          }
        }
      }
    }

    if (_target != null) {
      // Adjust dx/dy towards target
      final dxTarget = _target!.x + (_target!.width / 2) - x;
      final dyTarget = _target!.y + (_target!.height / 2) - y;
      final dist = sqrt(pow(dxTarget, 2) + pow(dyTarget, 2));

      if (dist > 0) {
        final speed = perFrame(8.0 + speedLevel * 2);
        // Slowly adjust current dx and dy
        final ndx = dxTarget / dist * speed;
        final ndy = dyTarget / dist * speed;
        x += ndx;
        y += ndy;
      } else {
        // direct move
        x += dx;
        y += dy;
      }
    } else {
      // Just move up if no target
      x += dx;
      y += dy;
    }

    if (x < 0 ||
        x >= state.width.toDouble() ||
        y < 0 ||
        y >= state.height.toDouble()) {
      state.removeEntity(this);
    }
  }
}
