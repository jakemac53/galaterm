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
    }
  }
}
