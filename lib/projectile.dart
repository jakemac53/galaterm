import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';

class Projectile extends Entity {
  final bool isEnemyProjectile;
  final int dx;
  final int dy;

  Projectile({
    required super.x,
    required super.y,
    this.dx = 0,
    required this.dy,
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
  void move(GameState state) {
    x += dx;
    y += dy;

    if (x < 0 || x >= state.width || y < 0 || y >= state.height) {
      state.removeEntity(this);
    }
  }

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    for (int pdy = 0; pdy < height; pdy++) {
      for (int pdx = 0; pdx < width; pdx++) {
        if (lines[pdy].length > pdx && lines[pdy][pdx] != ' ') {
          final targets = grid[x + pdx]?[y + pdy];
          if (targets != null) {
            for (final e in targets.toList()) {
              if (e != this && e.health > 0) {
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
    }
  }
}
