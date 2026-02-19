import 'dart:math';

import 'entity.dart';
import 'enemy.dart';
import 'game_state.dart';
import 'projectile.dart';
import 'constants.dart';

class EnemyFormation extends Entity {
  final List<Enemy> enemies = [];
  double _dx;
  final double speed;
  final double fireRatePerSecond;
  final Random _rand = Random();

  @override
  bool get isEnemy => true;

  EnemyFormation({
    required int rows,
    required int cols,
    double? speed,
    this.fireRatePerSecond = 0.5,
  }) : speed = speed ?? perFrame(2.0),
       _dx = speed ?? perFrame(2.0),
       super(x: 0.0, y: 0.0, character: ' ') {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double ex = (10 + c * 5).toDouble();
        final double ey = (2 + r * 2).toDouble();

        if (r == 0) {
          enemies.add(CruiserEnemy(x: ex, y: ey));
        } else if (r == 1) {
          enemies.add(SaucerEnemy(x: ex, y: ey));
        } else {
          enemies.add(DroneEnemy(x: ex, y: ey));
        }
      }
    }
  }

  @override
  Iterable<Entity> get activeEntities => enemies;

  @override
  void move(GameState state) {
    enemies.removeWhere((e) => e.health <= 0);

    if (enemies.isEmpty) {
      state.removeEntity(this);
      return;
    }
    
    // Probability of firing per tick
    if (_rand.nextDouble() < fireRatePerSecond / fps) {
      final firingEnemy = enemies[_rand.nextInt(enemies.length)];
      state.addEntity(
        Projectile(
          x: firingEnemy.x,
          y: firingEnemy.y + 1.0,
          dy: perFrame(10.0),
          isEnemyProjectile: true,
        ),
      );
    }

    bool hitEdge = false;
    for (final enemy in enemies) {
      if ((enemy.x <= 0 && _dx < 0) || (enemy.x >= state.width - 1 && _dx > 0)) {
        hitEdge = true;
        break;
      }
    }

    if (hitEdge) {
      _dx = -_dx;
      for (final enemy in enemies) {
        enemy.y += 1.0;
      }
    } else {
      for (final enemy in enemies) {
        enemy.x += _dx;
      }
    }
  }
}
