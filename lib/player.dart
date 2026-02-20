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
  BombProjectile? _activeBomb;

  int speedUpgradeLevel = 0;
  int bulletStrengthUpgradeLevel = 0;
  int armorUpgradeLevel = 0;

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
