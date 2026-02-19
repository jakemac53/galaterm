import 'entity.dart';

class GameState {
  final int width;
  final int height;
  int score = 0;

  final List<Entity> _entities = [];
  final List<Entity> _pendingAdds = [];
  final List<Entity> _pendingRemoves = [];

  GameState({this.width = 80, this.height = 40});

  List<Entity> get entities => List.unmodifiable(_entities);

  void addEntity(Entity entity) {
    _pendingAdds.add(entity);
  }

  void removeEntity(Entity entity) {
    _pendingRemoves.add(entity);
  }

  void tick() {
    // Move all enemies
    for (final entity in _entities) {
      entity.move(this);
    }

    // Build a grid of all active entities and their positions
    final grid = <int, Map<int, List<Entity>>>{};
    for (final group in _entities) {
      for (final e in group.activeEntities) {
        if (e.health > 0) {
          for (int dy = 0; dy < e.height; dy++) {
            for (int dx = 0; dx < e.width; dx++) {
              if (e.lines[dy].length > dx && e.lines[dy][dx] != ' ') {
                final list = grid
                    .putIfAbsent(e.gridX + dx, () => {})
                    .putIfAbsent(e.gridY + dy, () => []);
                if (!list.contains(e)) list.add(e);
              }
            }
          }
        }
      }
    }

    // Handle collisions, entities are in control of this.
    for (final entity in _entities) {
      entity.collide(this, grid);
    }

    _entities.addAll(_pendingAdds);
    _pendingAdds.clear();

    for (final entity in _pendingRemoves) {
      _entities.remove(entity);
    }
    _pendingRemoves.clear();
  }
}
