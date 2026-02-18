import 'entity.dart';
import 'game_state.dart';
import 'projectile.dart';

class Player extends Entity {
  Player({required super.x, required super.y})
      : super(health: 100, character: '▲');

  @override
  void tick(GameState state) {
    // Future player-specific tick logic
  }
  
  void moveTo(int newX, int newY) {
    x = newX;
    y = newY;
  }

  void fire(GameState state) {
    state.addEntity(Projectile(x: x, y: y - 1));
  }
}
