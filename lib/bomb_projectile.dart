import 'dart:math';
import 'package:nocterm/nocterm.dart';
import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';
import 'projectile.dart';

class BombProjectile extends Entity {
  bool _exploded = false;
  double _radius = 0;
  final double maxRadius = 15.0;
  final double growthSpeed = perFrame(30.0); // Grows to max radius in ~0.5s

  BombProjectile({required super.x, required super.y})
    : super(health: 1, character: '@', color: const Color(0xFFFF4500));

  void explode() {
    _exploded = true;
  }

  @override
  void move(GameState state) {
    if (!_exploded) {
      y -= perFrame(8.0);
      if (y < 0) {
        health = 0;
        state.removeEntity(this);
      }
    } else {
      _radius += growthSpeed;
      if (_radius >= maxRadius) {
        health = 0;
        state.removeEntity(this);
      }
    }
  }

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    if (!_exploded) {
      // Check for collision with enemy or projectile
      final list = grid[gridX]?[gridY];
      if (list != null) {
        for (final e in list) {
          if (e != this && (e.isEnemy || e is Projectile)) {
            explode();
            return;
          }
        }
      }
    } else {
      // Deal 1 damage per tick to all enemies in range
      for (final entity in state.entities) {
        if (entity.isEnemy) {
          for (final e in entity.activeEntities) {
            final dx = e.x - x;
            final dy = (e.y - y) * 2.0; // TerminalAspectRatio
            final dist = sqrt(dx * dx + dy * dy);
            if (dist <= _radius) {
              e.attack(1);
            }
          }
        }
      }
    }
  }

  @override
  Iterable<Entity> get activeEntities {
    if (!_exploded) return [this];

    // Create the ring of asterisks
    return [
      this, // Center
      ..._buildRingCells(),
    ];
  }

  List<Entity> _buildRingCells() {
    final cells = <Entity>[];
    if (_radius < 1) return cells;

    final numPoints = (_radius * 6).toInt().clamp(8, 64);
    for (int i = 0; i < numPoints; i++) {
      final angle = (2 * pi * i) / numPoints;
      // Adjust for terminal aspect ratio: dy is half of dx visually
      final dx = cos(angle) * _radius;
      final dy = sin(angle) * _radius * 0.5;

      cells.add(_ExplosionParticle(x: x + dx, y: y + dy));
    }
    return cells;
  }
}

class _ExplosionParticle extends Entity {
  _ExplosionParticle({required super.x, required super.y})
    : super(health: 1, character: '*', color: const Color(0xFFFF0000));
}
