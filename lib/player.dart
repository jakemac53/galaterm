import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'projectile.dart';
import 'constants.dart';

class Player extends Entity {
  double? _targetX;
  double? _targetY;
  final double speed = perFrame(12.0);
  int _fireCooldown = 0;
  final int _fireInterval = toTicks(0.5);

  Player({required super.x, required super.y})
    : super(
        health: 100,
        lines: ['<*>', '/ \\'],
        color: const Color(0xFF00FF00),
      );

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
  }

  void moveTo(double newX, double newY) {
    _targetX = newX;
    _targetY = newY;
  }

  void fire(GameState state) {
    if (_fireCooldown == 0) {
      state.addEntity(
        Projectile(x: x + 1.0, y: y - 1.0, dy: perFrame(-10.0), damage: 5),
      );
      _fireCooldown = _fireInterval;
    }
  }
}
