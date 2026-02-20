import 'package:nocterm/nocterm.dart';
import 'game_state.dart';

abstract class Entity {
  double x;
  double y;
  int health;
  List<String> lines;
  Color? color;
  Color? backgroundColor;

  Entity({
    required this.x,
    required this.y,
    this.health = 10,
    String? character,
    List<String>? lines,
    this.color,
    this.backgroundColor,
  }) : lines = lines ?? [character ?? ' '];

  int get gridX => x.round();
  int get gridY => y.round();

  int get width => lines.isEmpty
      ? 0
      : lines.fold(0, (max, line) => line.length > max ? line.length : max);
  int get height => lines.length;

  bool get isPlayer => false;
  bool get isEnemy => false;

  void move(GameState state) {}

  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {}

  void attack(int damage) {
    health -= damage;
  }

  Iterable<Entity> get activeEntities => [this];
}
