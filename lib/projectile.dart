import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';

class Projectile extends Entity {
  final bool isEnemyProjectile;

  Projectile({
    required super.x,
    required super.y,
    this.isEnemyProjectile = false,
  }) : super(
         health: 1,
         character: isEnemyProjectile ? 'v' : '|',
         color: isEnemyProjectile
             ? const Color(0xFFFFA500)
             : const Color(0xFF00E5FF),
       );

  @override
  bool get isEnemy => isEnemyProjectile;

  @override
  void tick(GameState state) {
    if (isEnemyProjectile) {
      y += 1;
    } else {
      y -= 1;
    }

    if (y < 0 || y >= state.height) {
      state.removeEntity(this);
      return;
    }

    for (final group in state.entities) {
      for (final e in group.activeEntities) {
        if (e != this && e.health > 0 && e.x == x && e.y == y) {
          if (isEnemyProjectile && e.isPlayer) {
            e.attack(10);
            state.removeEntity(this);
            return;
          } else if (!isEnemyProjectile && e.isEnemy) {
            e.attack(1);
            state.score += 10;
            state.removeEntity(this);
            return;
          }
        }
      }
    }
  }
}
