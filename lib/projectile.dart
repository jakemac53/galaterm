import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';

class Projectile extends Entity {
  Projectile({required super.x, required super.y})
    : super(health: 1, character: '|', color: const Color(0xFF00E5FF));

  @override
  void tick(GameState state) {
    y -= 1;
    if (y < 0) {
      state.removeEntity(this);
      return;
    }

    for (final group in state.entities) {
      for (final e in group.activeEntities) {
        if (e != this && e.health > 0 && e.x == x && e.y == y) {
          e.attack(1);
          state.removeEntity(this);
          return;
        }
      }
    }
  }
}
