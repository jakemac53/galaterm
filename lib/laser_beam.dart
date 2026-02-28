import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';
import 'projectile.dart';

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
            e.attack(state, damagePerTick);
            // Let it pierce!
          }
        }
      }
    }
  }
}
