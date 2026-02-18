import 'package:nocterm/nocterm.dart';
import 'game_state.dart';

abstract class Entity {
  int x;
  int y;
  int health;
  String character;
  Color? color;

  Entity({
    required this.x,
    required this.y,
    this.health = 10,
    required this.character,
    this.color,
  });

  bool get isPlayer => false;
  bool get isEnemy => false;

  void move(GameState state) {}

  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {}

  void attack(int damage) {
    health -= damage;
  }

  Iterable<Entity> get activeEntities => [this];
}
