import 'entity.dart';
import 'enemy.dart';
import 'game_state.dart';

class EnemyFormation extends Entity {
  final List<Enemy> enemies = [];
  int _dx = 1;
  int _tickCount = 0;
  final int moveInterval;

  EnemyFormation({required int rows, required int cols, this.moveInterval = 5})
      : super(x: 0, y: 0, character: ' ') {
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        enemies.add(Enemy(x: 10 + c * 4, y: 2 + r * 2));
      }
    }
  }

  @override
  Iterable<Entity> get activeEntities => enemies;

  @override
  void tick(GameState state) {
    enemies.removeWhere((e) => e.health <= 0);

    if (enemies.isEmpty) {
      state.removeEntity(this);
      return;
    }

    _tickCount++;
    if (_tickCount < moveInterval) {
      return;
    }
    _tickCount = 0;

    bool hitEdge = false;
    for (final enemy in enemies) {
      if ((enemy.x <= 0 && _dx < 0) || (enemy.x >= state.width - 1 && _dx > 0)) {
        hitEdge = true;
        break;
      }
    }

    if (hitEdge) {
      _dx = -_dx;
      for (final enemy in enemies) {
        enemy.y += 1;
      }
    } else {
      for (final enemy in enemies) {
        enemy.x += _dx;
      }
    }
  }
}
