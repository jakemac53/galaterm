import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'projectile.dart';

class Player extends Entity {
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
    // Future player-specific movement logic
  }
  
  void moveTo(double newX, double newY) {
    x = newX;
    y = newY;
  }

  void fire(GameState state) {
    state.addEntity(Projectile(x: x + 1.0, y: y - 1.0, dy: -1.0 / 6.0));
  }
}
