import 'package:nocterm/nocterm.dart';

import 'entity.dart';

class Enemy extends Entity {
  Enemy({
    required super.x,
    required super.y,
    super.health = 1,
    super.lines,
    super.color,
  });

  @override
  bool get isEnemy => true;
}

class CruiserEnemy extends Enemy {
  CruiserEnemy({required super.x, required super.y})
    : super(health: 3, lines: ['<AA>'], color: const Color(0xFFFF00FF));
}

class SaucerEnemy extends Enemy {
  SaucerEnemy({required super.x, required super.y})
    : super(health: 2, lines: ['(-)'], color: const Color(0xFF00FFFF));
}

class DroneEnemy extends Enemy {
  DroneEnemy({required super.x, required super.y})
    : super(health: 1, lines: ['[=]'], color: const Color(0xFFFF0000));
}
