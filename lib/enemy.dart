import 'package:nocterm/nocterm.dart';

import 'entity.dart';

class Enemy extends Entity {
  Enemy({required super.x, required super.y})
      : super(health: 1, character: 'W', color: const Color(0xFFFF0000));
      
  @override
  bool get isEnemy => true;
}
