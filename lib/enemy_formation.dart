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
  final double divingSpeed;
  final double returnSpeed;
  final Random _rand = Random();

  @override
  bool get isEnemy => true;

  EnemyFormation({
    required int rows,
    required int cols,
    double? speed,
    this.fireRatePerSecond = 0.5,
    this.divingSpeed = 8.0,
    this.returnSpeed = 10.0,
  }) : speed = speed ?? perFrame(2.0),
       _dx = speed ?? perFrame(2.0),
       super(x: 0.0, y: 0.0, character: ' ') {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double ex = (10 + c * 5).toDouble();
        final double ey = (2 + r * 2).toDouble();

        if (r == 0) {
          enemies.add(
            CruiserEnemy(
              x: ex,
              y: ey,
              divingSpeed: divingSpeed,
              returnSpeed: returnSpeed,
            ),
          );
        } else if (r == 1) {
          enemies.add(
            SaucerEnemy(
              x: ex,
              y: ey,
              divingSpeed: divingSpeed,
              returnSpeed: returnSpeed,
            ),
          );
        } else {
          enemies.add(
            DroneEnemy(
              x: ex,
              y: ey,
              divingSpeed: divingSpeed,
              returnSpeed: returnSpeed,
            ),
          );
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

    // 1. Determine if formation as a whole needs to shift down
    bool hitEdge = false;
    for (final enemy in enemies) {
      if (!enemy.isDiving && !enemy.isReturning) {
        if ((enemy.formationX <= 0 && _dx < 0) ||
            (enemy.formationX >= state.width - 1 && _dx > 0)) {
          hitEdge = true;
          break;
        }
      }
    }

    // 2. Update formation target positions and move entities
    if (hitEdge) {
      _dx = -_dx;
      for (final enemy in enemies) {
        enemy.formationY += 1.0;
        if (enemy.isDiving || enemy.isReturning) {
          enemy.move(state); // Update independent movement
        } else {
          enemy.y = enemy.formationY;
          enemy.x = enemy.formationX; // Ensure snapped to formation
        }
      }
    } else {
      for (final enemy in enemies) {
        enemy.formationX += _dx;
        if (enemy.isDiving || enemy.isReturning) {
          enemy.move(state); // Update independent movement
        } else {
          enemy.x = enemy.formationX;
          enemy.y = enemy.formationY; // Ensure snapped to formation
        }
      }
    }

    // Occasional dive trigger (chance per tick)
    if (_rand.nextDouble() < 0.005) {
      final available = enemies
          .where((e) => !e.isDiving && !e.isReturning)
          .toList();
      if (available.isNotEmpty) {
        available[_rand.nextInt(available.length)].startDive();
      }
    }
  }

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    for (final enemy in enemies.toList()) {
      enemy.collide(state, grid);
    }
  }
}
