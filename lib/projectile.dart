import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';

class Projectile extends Entity {
  final bool isEnemyProjectile;
  final double dx;
  final double dy;
  final int damage;

  Projectile({
    required super.x,
    required super.y,
    this.dx = 0,
    required this.dy,
    this.isEnemyProjectile = false,
    this.damage = 1,
    String? character,
    Color? color,
  }) : super(
         health: 1,
         character: character ?? (isEnemyProjectile ? 'v' : '|'),
         color:
             color ??
             (isEnemyProjectile
             ? const Color(0xFFFFA500)
                 : const Color(0xFF00E5FF)),
       );

  @override
  bool get isEnemy => isEnemyProjectile;

  @override
  void move(GameState state) {
    x += dx;
    y += dy;

    if (x < 0 ||
        x >= state.width.toDouble() ||
        y < 0 ||
        y >= state.height.toDouble()) {
      state.removeEntity(this);
    }
  }

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    for (int pdy = 0; pdy < height; pdy++) {
      for (int pdx = 0; pdx < width; pdx++) {
        if (lines[pdy].length > pdx && lines[pdy][pdx] != ' ') {
          final targets = grid[gridX + pdx]?[gridY + pdy];
          if (targets != null) {
            for (final e in targets.toList()) {
              if (e != this && e.health > 0 && e is! Projectile) {
                if (isEnemyProjectile && e.isPlayer) {
                  e.attack(damage);
                  state.removeEntity(this);
                  return;
                } else if (!isEnemyProjectile && e.isEnemy) {
                  e.attack(damage);
                  state.score += 10;
                  state.removeEntity(this);
                  return;
                }
              }
            }
          }
        }
      }
    }
  }
}

class LaserBeam extends Entity {
  int _ticksRemaining = toTicks(0.5);
  final int damagePerTick;

  LaserBeam({required super.x, required super.y, required this.damagePerTick})
    : super(
        health: 1,
        lines: List.generate((y).toInt(), (_) => ' '),
        backgroundColor: const Color(0xFF008080), // Teal
      ) {
    // Make it start at the top of the scren and end at the player position
    y = 0;
  }

  @override
  void move(GameState state) {
    _ticksRemaining--;
    if (_ticksRemaining <= 0) {
      health = 0;
      state.removeEntity(this);
    }
  }

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    // Apply damage to any enemies in its path
    for (int pdy = 0; pdy < height; pdy++) {
      final targets = grid[gridX]?[gridY + pdy];
      if (targets != null) {
        for (final e in targets.toList()) {
          if (e.isEnemy && e is! Projectile && e.health > 0) {
            e.attack(damagePerTick);
            // Let it pierce!
          }
        }
      }
    }
  }
}

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
