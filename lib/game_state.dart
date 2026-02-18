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
    for (final entity in _entities) {
      if (!_pendingRemoves.contains(entity)) {
        entity.move(this);
      }
    }

    final grid = <int, Map<int, List<Entity>>>{};
    for (final group in _entities) {
      if (!_pendingRemoves.contains(group)) {
        for (final e in group.activeEntities) {
          if (e.health > 0) {
            grid.putIfAbsent(e.x, () => {}).putIfAbsent(e.y, () => []).add(e);
          }
        }
      }
    }

    for (final entity in _entities) {
      if (!_pendingRemoves.contains(entity)) {
        entity.collide(this, grid);
      }
    }

    _entities.addAll(_pendingAdds);
    _pendingAdds.clear();

    for (final entity in _pendingRemoves) {
      _entities.remove(entity);
    }
    _pendingRemoves.clear();
  }
}
