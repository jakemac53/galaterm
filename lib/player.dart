import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'projectile.dart';

class Player extends Entity {
  Player({required super.x, required super.y})
    : super(health: 100, character: '▲', color: const Color(0xFF00FF00));

  @override
  bool get isPlayer => true;

  @override
  void move(GameState state) {
    // Future player-specific movement logic
  }
  
  void moveTo(int newX, int newY) {
    x = newX;
    y = newY;
  }

  void fire(GameState state) {
    state.addEntity(Projectile(x: x, y: y - 1));
  }
}
