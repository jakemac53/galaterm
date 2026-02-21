import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';

class OmegaLaser extends Entity {
  int _ticksRemaining = toTicks(3.0); // lasts for 3 seconds

  OmegaLaser({required super.x, required super.y})
    : super(
        health: 1,
        lines: List.generate((y).toInt(), (dy) {
          final yDiff = (y - dy).toDouble(); 
           final int halfWidth = yDiff.round();
          final int leftX = (x.round() - halfWidth);
          final String fullRow = "\\${'\\/' * halfWidth}/";
           
          if (leftX < 0) {
               final startIdx = -leftX;
            if (startIdx >= fullRow.length) return '';
            return fullRow.substring(startIdx);
           }
          return (' ' * leftX) + fullRow;
        }),
        color: const Color(0xFFFF00FF), // Magenta
        zIndex: 60,
      ) {
    x = 0; 
    y = 0;
  }

  @override
  void move(GameState state) {
    _ticksRemaining--;
    if (_ticksRemaining <= 0) {
      health = 0;
      state.removeEntity(this);
    }
  }

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        if (lines[dy].length > dx && lines[dy][dx] != ' ') {
          final targets = grid[gridX + dx]?[gridY + dy];
          if (targets != null) {
            for (final e in targets.toList()) {
              if (e.isEnemy && e.health > 0) {
                e.attack(5);
              }
            }
          }
        }
      }
    }
  }
}
