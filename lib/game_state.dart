import 'entity.dart';

class GameState {
  final int width;
  final int height;

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
        entity.tick(this);
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
