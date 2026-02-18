import 'game_state.dart';

abstract class Entity {
  int x;
  int y;
  int health;
  String character;

  Entity({
    required this.x,
    required this.y,
    this.health = 10,
    required this.character,
  });

  void tick(GameState state) {}

  void attack(int damage) {
    health -= damage;
  }
}
