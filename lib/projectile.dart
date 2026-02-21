import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';

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
    super.lines,
    Color? color,
    super.colors,
  }) : super(
         health: 1,
         zIndex: 40,
         character: lines == null
             ? (character ?? (isEnemyProjectile ? 'v' : '|'))
             : null,
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
