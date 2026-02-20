import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'enemy.dart';
import 'game_state.dart';
import 'projectile.dart';
import 'constants.dart';
import 'item.dart';

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
    // 3 rows, 8 cols = 24 enemies
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double ex = (24 + c * 4).toDouble();
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

  EnemyFormation.vShape({
    double? speed,
    this.fireRatePerSecond = 0.5,
    this.divingSpeed = 8.0,
    this.returnSpeed = 10.0,
  }) : speed = speed ?? perFrame(2.0),
       _dx = speed ?? perFrame(2.0),
       super(x: 0.0, y: 0.0, character: ' ') {
    // Solid V-shape (Arrow), ~24 enemies
    final pattern = [
      [0, 1, 2, 3, 4, 5, 6, 7, 8], // Row 0 (Top wide)
      [1, 2, 3, 4, 5, 6, 7], // Row 1
      [2, 3, 4, 5, 6], // Row 2
      [3, 4, 5], // Row 3 (Bottom point)
    ];
    for (int r = 0; r < pattern.length; r++) {
      for (final c in pattern[r]) {
        final double ex = (22 + c * 4).toDouble();
        final double ey = (2 + r * 2).toDouble();
        
        // Outer edges vs Inner core
        final isOuter = c == pattern[r].first || c == pattern[r].last || r == 0;

        if (isOuter) {
          enemies.add(
            DroneEnemy(
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
            CruiserEnemy(
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

  EnemyFormation.diamond({
    double? speed,
    this.fireRatePerSecond = 0.5,
    this.divingSpeed = 8.0,
    this.returnSpeed = 10.0,
  }) : speed = speed ?? perFrame(2.0),
       _dx = speed ?? perFrame(2.0),
       super(x: 0.0, y: 0.0, character: ' ') {
    // Filled diamond, ~25 enemies
    final pattern = [
      [3], // Row 0
      [2, 3, 4], // Row 1
      [1, 2, 3, 4, 5], // Row 2
      [0, 1, 2, 3, 4, 5, 6], // Row 3 (center)
      [1, 2, 3, 4, 5], // Row 4
      [2, 3, 4], // Row 5
      [3], // Row 6
    ];
    for (int r = 0; r < pattern.length; r++) {
      for (final c in pattern[r]) {
        final double ex = (26 + c * 4).toDouble();
        final double ey = (2 + r * 2).toDouble();
        
        final isOuter =
            c == pattern[r].first || c == pattern[r].last || r == 0 || r == 6;

        if (isOuter) {
          enemies.add(
            SaucerEnemy(
              x: ex,
              y: ey,
              divingSpeed: divingSpeed,
              returnSpeed: returnSpeed,
            ),
          );
        } else if (c == 3 && r == 3) {
          // Absolute center
          enemies.add(
            CruiserEnemy(
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

  EnemyFormation.twinColumns({
    double? speed,
    this.fireRatePerSecond = 0.5,
    this.divingSpeed = 8.0,
    this.returnSpeed = 10.0,
  }) : speed = speed ?? perFrame(2.0),
       _dx = speed ?? perFrame(2.0),
       super(x: 0.0, y: 0.0, character: ' ') {
    // 6 rows * 4 cols (2 left, 2 right) = 24 enemies
    for (int r = 0; r < 6; r++) {
      for (final c in [0, 1, 6, 7]) {
        final double ex = (24 + c * 4).toDouble();
        final double ey = (2 + r * 2).toDouble();
        
        final isOuterColumn = c == 0 || c == 7;

        if (isOuterColumn) {
          enemies.add(
            DroneEnemy(
              x: ex,
              y: ey,
              divingSpeed: divingSpeed,
              returnSpeed: returnSpeed,
            ),
          );
        } else if (r < 2) {
          enemies.add(
            CruiserEnemy(
              x: ex,
              y: ey,
              divingSpeed: divingSpeed,
              returnSpeed: returnSpeed,
            ),
          );
        } else {
          enemies.add(
            SaucerEnemy(
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

  EnemyFormation.boss({required double x, required double y})
    : speed = 0,
      _dx = 0,
      fireRatePerSecond = 0,
      divingSpeed = 0,
      returnSpeed = 0,
      super(x: 0, y: 0, character: ' ') {
    enemies.add(BossEnemy(x: x, y: y));
  }

  EnemyFormation.hydraBoss({required double x, required double y})
    : speed = 0,
      _dx = 0,
      fireRatePerSecond = 0,
      divingSpeed = 0,
      returnSpeed = 0,
      super(x: 0, y: 0, character: ' ') {
    enemies.add(HydraBossEnemy(x: x, y: y));
  }

  @override
  Iterable<Entity> get activeEntities => enemies;

  @override
  void move(GameState state) {
    // Collect dying enemies to check for drops
    final dying = enemies.where((e) => e.health <= 0).toList();
    for (final enemy in dying) {
      if (enemy is BossEnemy ||
          (enemy is HydraBossEnemy && enemy.splitLevel == 3)) {
        // Massive Boss explosion: grid of explosions
        for (int i = 0; i < 3; i++) {
          for (int j = 0; j < 2; j++) {
            state.addEntity(
              Explosion(
                x: enemy.x + i * 8 + _rand.nextInt(4),
                y: enemy.y + j * 3 + _rand.nextInt(2),
                count: 12,
                color: const Color(0xFFFF0000),
              ),
            );
          }
        }
        // Boss Jackpot! 15 money items spread across its large hull
        for (int i = 0; i < 15; i++) {
          state.addEntity(
            Item(
              x: enemy.x + _rand.nextInt(24),
              y: enemy.y + _rand.nextInt(6),
              type: ItemType.money,
            ),
          );
        }
      } else if (enemy is HydraBossEnemy) {
        // Hydra boss splits instead of completely blowing up if it's not the final split level
        state.addEntity(
          Explosion(
            x: enemy.x + enemy.width / 2,
            y: enemy.y + enemy.height / 2,
            count: 10,
            color: const Color(0xFF00FF00),
          ),
        );
        enemies.addAll(enemy.split());
      } else {
        // Standard enemy explosion
        state.addEntity(
          Explosion(
            x: enemy.x + enemy.width / 2,
            y: enemy.y + enemy.height / 2,
            color: enemy is FireEnemy
                ? const Color(0xFFFF4500)
                : const Color(0xFFFFFF00),
          ),
        );

        if (_rand.nextDouble() < 0.3) {
          // 30% drop chance for normal enemies
          ItemType type;
          final r = _rand.nextDouble();
          if (r < 0.6) {
            type = ItemType.money; // 60% of drops are money
          } else {
            // Remaining 40% split between others
            final otherTypes = ItemType.values
                .where((t) => t != ItemType.money)
                .toList();
            type = otherTypes[_rand.nextInt(otherTypes.length)];
          }
          state.addEntity(Item(x: enemy.x, y: enemy.y, type: type));
        }
      }
    }
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
          damage: 10,
        ),
      );
    }

    // 1. Determine if formation as a whole needs to shift down
    bool hitEdge = false;
    for (final enemy in enemies) {
      if (!enemy.isDiving &&
          !enemy.isReturning &&
          enemy is! BossEnemy &&
          enemy is! HydraBossEnemy) {
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
        if (enemy is! HydraBossEnemy) {
          enemy.formationY += 1.0;
        }
        enemy.move(state);
        if (!enemy.isDiving &&
            !enemy.isReturning &&
            enemy is! BossEnemy &&
            enemy is! HydraBossEnemy) {
          enemy.y = enemy.formationY;
          enemy.x = enemy.formationX;
        }
      }
    } else {
      for (final enemy in enemies) {
        if (enemy is! HydraBossEnemy) {
          enemy.formationX += _dx;
        }
        enemy.move(state);
        if (!enemy.isDiving &&
            !enemy.isReturning &&
            enemy is! BossEnemy &&
            enemy is! HydraBossEnemy) {
          enemy.x = enemy.formationX;
          enemy.y = enemy.formationY;
        }
      }
    }

    // Occasional dive trigger (chance per tick)
    if (_rand.nextDouble() < 0.005) {
      final available = enemies
          .where((e) => !e.isDiving && !e.isReturning && e is! BossEnemy)
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
