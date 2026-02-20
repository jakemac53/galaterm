import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'projectile.dart';
import 'constants.dart';
import 'item.dart';
import 'bomb_projectile.dart';

class Player extends Entity {
  double? _targetX;
  double? _targetY;
  double get speed {
    final baseSpeed = 12.0 + (speedUpgradeLevel * 2.0);
    return _speedBoostTicks > 0
        ? perFrame(baseSpeed * 2.0)
        : perFrame(baseSpeed);
  }
  int _fireCooldown = 0;
  int get fireInterval => _rapidFireTicks > 0 ? toTicks(0.125) : toTicks(0.25);

  int _shieldHealth = 0;
  int _speedBoostTicks = 0;
  int _rapidFireTicks = 0;
  int _onFireTicks = 0;
  BombProjectile? _activeBomb;

  int speedUpgradeLevel = 0;
  int bulletStrengthUpgradeLevel = 0;
  int armorUpgradeLevel = 0;
  int homingMissileLevel = 0;
  int laserBeamLevel = 0;

  int _homingCooldown = 0;
  int _laserCooldown = 0;

  Player({required super.x, required super.y})
    : super(
        health: 100,
        lines: ['<*>', '/ \\'],
        color: const Color(0xFF00FF00),
      );

  int get maxHealth => 100 + (armorUpgradeLevel * 25);

  @override
  bool get isPlayer => true;

  @override
  void move(GameState state) {
    if (_targetX == null || _targetY == null) return;

    final dx = _targetX! - x;
    final dy = _targetY! - y;

    // Terminal characters are typically ~2x taller than they are wide.
    // We scale dy by 2.0 to calculate a "visual distance" so that
    // diagonal movement has a consistent perceived speed.
    final visualDy = dy * 2.0;
    final visualDistance = sqrt(dx * dx + visualDy * visualDy);

    if (visualDistance <= speed) {
      x = _targetX!;
      y = _targetY!;
    } else {
      // We step by speed along the visual vector, then convert back to grid units.
      x += (dx / visualDistance) * speed;
      y += (dy / visualDistance) * speed;
    }

    // Clamp to screen bounds
    x = x.clamp(0.0, (state.width - width).toDouble());
    y = y.clamp(0.0, (state.height - height).toDouble());

    if (_fireCooldown > 0) _fireCooldown--;
    if (_speedBoostTicks > 0) _speedBoostTicks--;
    if (_rapidFireTicks > 0) _rapidFireTicks--;
    if (_homingCooldown > 0) _homingCooldown--;
    if (_laserCooldown > 0) _laserCooldown--;

    // Fire damage: 1 damage every 0.2s (12 ticks at 60fps) for 5s
    if (_onFireTicks > 0) {
      if (_onFireTicks % 12 == 0) {
        attack(1);
      }
      _onFireTicks--;
    }

    if (homingMissileLevel > 0 && _homingCooldown <= 0) {
      state.addEntity(
        HomingMissile(
          x: x + width,
          y: y,
          speedLevel: homingMissileLevel,
          damage: 15 + homingMissileLevel * 5,
        ),
      );
      _homingCooldown = toTicks(1.0);
    }

    if (laserBeamLevel > 0 && _laserCooldown <= 0) {
      state.addEntity(
        LaserBeam(x: x - 1.0, y: y, damagePerTick: 2 + laserBeamLevel * 2),
      );
      _laserCooldown = toTicks(5.0);
    }

    fire(state);
  }

  @override
  Iterable<Entity> get activeEntities => [
    this,
    if (_shieldHealth > 0) Shield(x: x, y: y - 1, health: _shieldHealth),
  ];

  void collect(Item item, GameState state) {
    switch (item.type) {
      case ItemType.money:
        state.galabucks += 100;
        break;
      case ItemType.bomb:
        state.bombs += 1;
        break;
      case ItemType.shield:
        _shieldHealth += 25;
        break;
      case ItemType.speedBoost:
        _speedBoostTicks = toTicks(10.0);
        break;
      case ItemType.rapidFire:
        _rapidFireTicks = toTicks(10.0);
        break;
    }
  }

  @override
  void attack(int damage) {
    if (_shieldHealth > 0) {
      if (_shieldHealth >= damage) {
        _shieldHealth -= damage;
        return;
      } else {
        final remaining = damage - _shieldHealth;
        _shieldHealth = 0;
        super.attack(remaining);
        return;
      }
    }
    super.attack(damage);
  }

  void moveTo(double newX, double newY) {
    _targetX = newX;
    _targetY = newY;
  }

  void fire(GameState state) {
    if (_fireCooldown == 0) {
      final damage = 10 + (bulletStrengthUpgradeLevel * 5);
      state.addEntity(
        Projectile(x: x + 1.0, y: y - 1.0, dy: perFrame(-10.0), damage: damage),
      );
      _fireCooldown = fireInterval;
    }
  }

  void useBomb(GameState state) {
    if (_activeBomb != null && _activeBomb!.health > 0) {
      _activeBomb!.explode();
      _activeBomb = null;
    } else if (state.bombs > 0) {
      state.bombs--;
      _activeBomb = BombProjectile(x: x + 1.0, y: y - 1.0);
      state.addEntity(_activeBomb!);
    }
  }

  void setOnFire() {
    // 5 seconds of fire at 60fps = 300 ticks
    _onFireTicks = toTicks(5.0);
  }

  @override
  Color? get color {
    if (_onFireTicks > 0 && _onFireTicks % 10 < 5) {
      return const Color(0xFFFF4500); // Flashing orange red
    }
    return super.color;
  }
}

class Shield extends Entity {
  Shield({required super.x, required super.y, required super.health})
    : super(lines: ['___'], color: _getShieldColor(health));

  static Color _getShieldColor(int health) {
    if (health >= 25) return const Color(0xFF00FF00); // Full or multiple

    final double ratio = health / 25.0;
    final r = (255 * (1.0 - ratio)).toInt();
    final g = (255 * ratio).toInt();
    return Color.fromARGB(255, r, g, 0);
  }
}
