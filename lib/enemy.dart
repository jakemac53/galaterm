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
    this.diesOffscreen = false,
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
  final bool diesOffscreen;

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
        if (diesOffscreen) {
          state.removeEntity(this);
          return;
        }
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
    super.diesOffscreen,
    int healthMultiplier = 1,
  }) : super(
         health: 40 * healthMultiplier,
         lines: ['<V>'],
         color: const Color(0xFFFF00FF),
       );
}

class SaucerEnemy extends Enemy {
  SaucerEnemy({
    required super.x,
    required super.y,
    super.divingSpeed,
    super.returnSpeed,
    super.diesOffscreen,
    int healthMultiplier = 1,
  }) : super(
         health: 30 * healthMultiplier,
         lines: ['(-)'],
         color: const Color(0xFF00FFFF),
       );
}

class DroneEnemy extends Enemy {
  DroneEnemy({
    required super.x,
    required super.y,
    super.divingSpeed,
    super.returnSpeed,
    super.diesOffscreen,
    int healthMultiplier = 1,
  }) : super(
         health: 20 * healthMultiplier,
         lines: ['[=]'],
         color: const Color(0xFFFF0000),
       );
}

class FireEnemy extends Enemy {
  int _shotCooldown = 0;

  FireEnemy({
    required super.x,
    required super.y,
    super.divingSpeed,
    super.returnSpeed,
    super.diesOffscreen,
    int healthMultiplier = 1,
  }) : super(
         health: 40 * healthMultiplier,
         lines: ['{^}'],
         color: const Color(0xFFFF4500),
       );

  @override
  void move(GameState state) {
    super.move(state);

    if (!isReturning && _shotCooldown <= 0) {
      state.addEntity(FlameProjectile(x: x + 1, y: y + 1, dy: perFrame(12.0)));
      _shotCooldown = toTicks(1.5);
    }
    if (_shotCooldown > 0) _shotCooldown--;
  }
}

class FlameProjectile extends Projectile {
  FlameProjectile({required super.x, required super.y, required super.dy})
    : super(isEnemyProjectile: true, damage: 5);

  @override
  Color? get color => const Color(0xFFFF4500);

  @override
  List<String> get lines => [gridY % 2 == 0 ? 'w' : 'v'];

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    // Custom collision to apply fire debuff
    final targets = grid[gridX]?[gridY];
    if (targets != null) {
      for (final e in targets) {
        if (e is Player) {
          e.attack(damage);
          e.setOnFire();
          state.removeEntity(this);
          return;
        }
      }
    }
    super.collide(state, grid);
  }
}

class BossEnemy extends Enemy {
  int _shotCooldown = 0;

  BossEnemy({required super.x, required super.y, int healthMultiplier = 1})
    : super(
        health: 1500 * healthMultiplier,
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
    // Boss only hovers in a wide sweeping pattern now
    x = 28.0 + 22.0 * sin(state.ticks / 40.0);
    y = 5.0 + 3.0 * cos(state.ticks / 25.0);

    // Boss fires 4 projectiles constantly
    if (_shotCooldown <= 0) {
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
      
      // Also occasionally spawn an enemy from a pool
      if (_rand.nextDouble() < 0.2) {
        final spawnX = x + 12;
        final spawnY = y + 6;

        Enemy spawnedEnemy;
        if (_rand.nextBool()) {
          spawnedEnemy = DroneEnemy(
            x: spawnX,
            y: spawnY,
            divingSpeed: 8.0,
            returnSpeed: 10.0,
            diesOffscreen: true,
            healthMultiplier:
                health ~/ 1500, // Roughly preserve the multiplier for adds
          );
        } else {
          spawnedEnemy = FireEnemy(
            x: spawnX,
            y: spawnY,
            divingSpeed: 8.0,
            returnSpeed: 10.0,
            diesOffscreen: true,
            healthMultiplier: health ~/ 1500,
          );
        }
        state.addEntity(spawnedEnemy..startDive());
      }
    }
    if (_shotCooldown > 0) _shotCooldown--;
  }
}

class HydraBossEnemy extends Enemy {
  int _shotCooldown = 0;
  final int splitLevel;

  final int healthMultiplier;

  HydraBossEnemy({
    required super.x,
    required super.y,
    this.splitLevel = 0,
    double vx = 4.0,
    double vy = 2.0,
    this.healthMultiplier = 1,
  }) : super(
         health: (1200 ~/ (pow(2, splitLevel))) * healthMultiplier,
         lines: _getLinesForLevel(splitLevel),
         color: const Color(0xFF00FF00),
       ) {
    _vx = vx;
    _vy = vy;
  }

  static List<String> _getLinesForLevel(int level) {
    if (level == 0) {
      return [
        r'    /----------\    ',
        r'   /| °      ° |\   ',
        r'  / |   ^  ^   | \  ',
        r' |  | \====/   |  | ',
        r' |__|__________|__| ',
        r'  \/            \/  ',
      ];
    }
    if (level == 1) {
      return [
        r'   /------\   ',
        r'  /| °  ° |\  ',
        r' | | \==/ | | ',
        r' |\|______|/| ',
        r'  \/      \/  ',
      ];
    }
    if (level == 2) {
      return [r'  /----\  ', r' / °  ° \ ', r' \  ==  / ', r'  \____/  '];
    }
    return [r' /--\ ', r' |><| ', r' \__/ '];
  }

  @override
  void move(GameState state) {
    x += perFrame(_vx);
    y += perFrame(_vy);

    // Bounce off walls
    if (x <= 0) {
      _vx = _vx.abs();
      x = 0;
    } else if (x >= state.width - width) {
      _vx = -_vx.abs();
      x = state.width - width.toDouble();
    }

    if (y <= 0) {
      _vy = _vy.abs();
      y = 0;
    } else if (y >= state.height * 0.6) {
      _vy = -_vy.abs();
      y = state.height * 0.6;
    }

    if (_shotCooldown <= 0) {
      final cannons = <double>[];
      if (splitLevel == 0) {
        cannons.addAll([4, width / 2.0 - 1, width - 5]);
      } else if (splitLevel == 1) {
        cannons.addAll([2, width - 3]);
      } else {
        cannons.add(width / 2.0);
      }
      for (final offset in cannons) {
        state.addEntity(
          Projectile(
            x: x + offset,
            y: y + height.toDouble(),
            dy: perFrame(10.0 + splitLevel * 3),
            isEnemyProjectile: true,
            damage: 10,
          ),
        );
      }
      _shotCooldown = toTicks(1.5 - splitLevel * 0.2);
    }
    if (_shotCooldown > 0) _shotCooldown--;
  }

  List<HydraBossEnemy> split() {
    if (splitLevel >= 3) return [];
    return [
      HydraBossEnemy(
        x: x,
        y: y,
        splitLevel: splitLevel + 1,
        vx: -(_vx.abs() + 2.0),
        vy: -(_vy.abs() + 1.0),
        healthMultiplier: healthMultiplier,
      ),
      HydraBossEnemy(
        x: x + width / 2,
        y: y,
        splitLevel: splitLevel + 1,
        vx: _vx.abs() + 2.0,
        vy: -(_vy.abs() + 1.0),
        healthMultiplier: healthMultiplier,
      ),
    ];
  }
}
