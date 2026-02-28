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
         dy: perFrame(-20.0),
         lines: ['^', 'Y'],
         colors: [
           const Color(0xFF4682B4), // Steely blue
           const Color(0xFFFFFF00), // Yellow
           const Color(0xFFFFA500), // Orange
           const Color(0xFFFF0000), // Red
         ],
       );

  int _tick = 0;

  @override
  void move(GameState state) {
    _tick++;
    if (_tick % 3 == 0 && colors != null && colors!.length >= 2) {
      final trailColors = [
        const Color(0xFFFFFF00),
        const Color(0xFFFFA500),
        const Color(0xFFFF0000),
      ];
      colors![1] = trailColors[(_tick ~/ 3) % 3];
    }

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
        final speed = perFrame(20.0);
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

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    if (health <= 0) return;

    // Check if we will hit something
    bool willHit = false;
    for (int pdy = 0; pdy < height; pdy++) {
      for (int pdx = 0; pdx < width; pdx++) {
        if (lines[pdy].length > pdx && lines[pdy][pdx] != ' ') {
          final targets = grid[gridX + pdx]?[gridY + pdy];
          if (targets != null) {
            for (final e in targets.toList()) {
              if (e != this && e.health > 0 && e is! Projectile && e.isEnemy) {
                willHit = true;
                break;
              }
            }
          }
        }
      }
    }

    if (willHit) {
      // Cause a tiny explosion! (Radius 3)
      final radius = 3.0; // Very small explosion
      final numPoints = (radius * 6).toInt();
      for (int i = 0; i < numPoints; i++) {
        final angle = (2 * pi * i) / numPoints;
        final dx = cos(angle) * radius;
        final dy = sin(angle) * radius * 0.5;
        state.addEntity(_MissileExplosionParticle(x: x + dx, y: y + dy));
      }

      // Deal Area Of Effect Damage to all enemies in radius
      for (final entity in state.entities) {
        if (entity.isEnemy) {
          for (final e in entity.activeEntities) {
            final targetDx = e.x - x;
            final targetDy = (e.y - y) * 2.0;
            final dist = sqrt(targetDx * targetDx + targetDy * targetDy);
            if (dist <= radius && e.health > 0) {
              e.attack(state, (damage * 0.5).toInt()); // 50% splash damage
            }
          }
        }
      }
    }

    // Call standard projectile collide to deal direct damage and remove self
    super.collide(state, grid);
  }
}

class _MissileExplosionParticle extends Entity {
  int _ticksRemaining = 6; // Lasts 0.1s

  _MissileExplosionParticle({required super.x, required super.y})
    : super(health: 1, character: '*', color: const Color(0xFFFF4500));

  @override
  void move(GameState state) {
    _ticksRemaining--;
    if (_ticksRemaining <= 0) {
      health = 0;
      state.removeEntity(this);
    }
  }
}
