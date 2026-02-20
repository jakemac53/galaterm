import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';
import 'player.dart';
import 'projectile.dart';

class Enemy extends Entity {
  Enemy({
    required super.x,
    required super.y,
    super.health = 1,
    super.lines,
    super.color,
    this.divingSpeed = 8.0,
    this.returnSpeed = 10.0,
  }) {
    formationX = x;
    formationY = y;
  }

  bool isDiving = false;
  bool isReturning = false;
  double _vx = 0;
  double _vy = 0;
  int _nextDirTicks = 0;
  final Random _rand = Random();

  // The position in the formation this enemy should occupy
  double formationX = 0;
  double formationY = 0;

  final double divingSpeed;
  final double returnSpeed;

  @override
  bool get isEnemy => true;

  void startDive() {
    isDiving = true;
    isReturning = false;
    _nextDirTicks = 0; // Trigger immediate dir calculation
  }

  @override
  void move(GameState state) {
    if (!isDiving && !isReturning) return;

    if (isDiving) {
      if (_nextDirTicks <= 0) {
        // Find player
        Player? player;
        for (final e in state.entities) {
          if (e is Player) player = e;
        }

        double tx = (state.width / 2);
        if (player != null) {
          tx = player.x;
        }

        // Vertical speed is 80% of total diving speed
        _vy = perFrame(divingSpeed * 0.8);

        // Trend X towards player with some noise (X speed is 60% of total diving speed)
        final dx = tx - x;
        final xSpeed = perFrame(divingSpeed * 0.6);
        _vx =
            (dx > 0 ? xSpeed : -xSpeed) +
            (_rand.nextDouble() - 0.5) * perFrame(divingSpeed * 0.2);

        // Switch every 1.5 - 3 seconds
        _nextDirTicks = toTicks(1.5 + _rand.nextDouble() * 1.5);
      }

      x += _vx;
      y += _vy;
      _nextDirTicks--;

      // If off bottom, wrap to top and start returning
      if (y > state.height) {
        y = -height.toDouble();
        isDiving = false;
        isReturning = true;
      }
    } else if (isReturning) {
      // Move towards formation position
      final dx = formationX - x;
      final dy = formationY - y;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist < 1.0) {
        x = formationX;
        y = formationY;
        isReturning = false;
      } else {
        final speed = perFrame(returnSpeed);
        x += (dx / dist) * speed;
        y += (dy / dist) * speed;
      }
    }
  }

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    if (health <= 0) return;

    // Check for player collision
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        final cellEntities = grid[gridX + dx]?[gridY + dy];
        if (cellEntities != null) {
          for (final other in cellEntities) {
            if (other is Player && other.health > 0) {
              // Damage each other based on current health
              final enemyDamage = health;
              final playerDamage = other.health;

              other.attack(enemyDamage);
              attack(playerDamage);

              if (health <= 0) {
                state.removeEntity(this);
              }
              return;
            }
          }
        }
      }
    }
  }
}

class CruiserEnemy extends Enemy {
  CruiserEnemy({
    required super.x,
    required super.y,
    super.divingSpeed,
    super.returnSpeed,
  }) : super(health: 40, lines: ['<V>'], color: const Color(0xFFFF00FF));
}

class SaucerEnemy extends Enemy {
  SaucerEnemy({
    required super.x,
    required super.y,
    super.divingSpeed,
    super.returnSpeed,
  }) : super(health: 30, lines: ['(-)'], color: const Color(0xFF00FFFF));
}

class DroneEnemy extends Enemy {
  DroneEnemy({
    required super.x,
    required super.y,
    super.divingSpeed,
    super.returnSpeed,
  }) : super(health: 20, lines: ['[=]'], color: const Color(0xFFFF0000));
}

class BossEnemy extends Enemy {
  int _shotCooldown = 0;

  BossEnemy({required super.x, required super.y})
    : super(
        health: 1500,
        lines: [
          r'   _____        _____   ',
          r'  /     \      /     \  ',
          r' <|XXXXX|======|XXXXX|> ',
          r'  \MMMMM/  ||  \MMMMM/  ',
          r'   |___|  /MM\  |___|   ',
          r'   v   v  \WW/  v   v   ',
        ],
        color: const Color(0xFFFF3333),
      );

  @override
  void move(GameState state) {
    if (isDiving || isReturning) {
      super.move(state);
    } else {
      // Boss hovers in a wide sweeping pattern
      x = 28.0 + 22.0 * sin(state.ticks / 40.0);
      y = 5.0 + 3.0 * cos(state.ticks / 25.0);
    }

    // Boss fires 4 projectiles constantly if not returning
    if (!isReturning && _shotCooldown <= 0) {
      final cannons = [2, 8, 16, 22]; // Approximate X offsets for guns
      for (final offset in cannons) {
        state.addEntity(
          Projectile(
            x: x + offset,
            y: y + 5,
            dy: perFrame(14.0),
            isEnemyProjectile: true,
            damage: 10,
          ),
        );
      }
      _shotCooldown = toTicks(0.8); // Slower fire rate
    }
    if (_shotCooldown > 0) _shotCooldown--;

    // Reduced diving frequency for boss
    if (!isDiving && !isReturning && _rand.nextDouble() < 0.008) {
      startDive();
    }
  }
}
