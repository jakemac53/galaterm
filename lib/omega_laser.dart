import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';

class OmegaLaser extends Entity {
  int _ticksRemaining = toTicks(1.0); // lasts for 1 second

  OmegaLaser({required super.x, required super.y})
    : super(
        health: 1,
        lines: List.generate((y).toInt(), (dy) {
           // We are generating a V shape originating from x,y spreading outward as we go UP (lower dy)
           final yDiff = (y - dy).toDouble(); 
           // Make it spread horizontally by 1 for every 1 dy
           final int halfWidth = yDiff.round();
           final int leftX = (x.round() - halfWidth);
           
           if (leftX < 0) {
               // Too far left, cut off
               final width = (halfWidth * 2).clamp(1, 9999);
               final startIdx = -leftX;
               if (startIdx >= width) return ''; // Completely offscreen left (unlikely)
               final int visibleWidth = width - startIdx;
               return ' ' * 0 + '\\/' * (visibleWidth ~/ 2);
           }
           final widthStr = '\\/' * halfWidth; 
           return (' ' * leftX) + widthStr;
        }),
        backgroundColor: const Color(0xFFFF00FF), // Magenta
      ) {
    // Start at top of screen
    x = 0; // x doesn't really matter for drawing since it handles its own left spacing
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
    // Damage everything that is within the laser's bounds
    // We already know it basically kills everything
    for (int pdy = 0; pdy < height; pdy++) {
        final targets = grid[gridX]?[gridY + pdy];
        if (targets != null) {
             for (final e in targets.toList()) {
                 if (e.isEnemy && e.health > 0) {
                     e.attack(9999); 
                 }
             }
        }
        
    }
    // Also since our hit box logic for this hacky V shape object might be slightly off with the bounding box, 
    // let's just do a blanket sweeping collision on anything that overlaps its height
    for (final e in state.entities) {
        if (e == this) continue;
        for (final active in e.activeEntities) {
            if (active.isEnemy && active.health > 0) {
                 active.attack(9999);
            }
        }
    }
  }
}
