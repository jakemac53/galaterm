import 'dart:math';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'item.dart';
import 'constants.dart';

class GameState {
  final int width;
  final int height;
  int score = 0;
  int galabucks = 0;
  int bombs = 0;
  int ticks = 0;

  final List<Entity> _entities = [];
  final List<Entity> _pendingAdds = [];
  final List<Entity> _pendingRemoves = [];

  GameState({this.width = 80, this.height = 40});

  List<Entity> get entities => List.unmodifiable(_entities);

  bool get isGameOver {
    for (final entity in _entities) {
      for (final active in entity.activeEntities) {
        if (active.isPlayer && active.health > 0) return false;
      }
    }
    return true;
  }

  bool get isLevelComplete {
    for (final entity in _entities) {
      for (final active in entity.activeEntities) {
        if (active.isEnemy && active.health > 0) return false;
        if (active is Item && active.health > 0) return false;
      }
    }
    return true;
  }

  void addEntity(Entity entity) {
    _pendingAdds.add(entity);
  }

  void removeEntity(Entity entity) {
    _pendingRemoves.add(entity);
  }

  void tick() {
    ticks++;
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

class Explosion extends Entity {
  final List<ExplosionParticle> _particles = [];
  int _ticksRemaining = toTicks(0.5);

  Explosion({
    required super.x,
    required super.y,
    int count = 8,
    Color color = const Color(0xFFFFFF00),
  }) : super(health: 1) {
    final rand = Random();
    for (int i = 0; i < count; i++) {
      final angle = rand.nextDouble() * 2 * pi;
      final speed = 2.0 + rand.nextDouble() * 4.0;
      _particles.add(
        ExplosionParticle(
          x: x,
          y: y,
          dx: perFrame(cos(angle) * speed),
          dy: perFrame(sin(angle) * speed * 0.5),
          character: i % 2 == 0 ? '*' : '+',
          color: color,
        ),
      );
    }
  }

  @override
  void move(GameState state) {
    for (final p in _particles) {
      p.move(state);
    }
    _ticksRemaining--;
    if (_ticksRemaining <= 0) {
      health = 0;
      state.removeEntity(this);
    }
  }

  @override
  Iterable<Entity> get activeEntities => _particles;
}

class ExplosionParticle extends Entity {
  final double dx;
  final double dy;

  ExplosionParticle({
    required super.x,
    required super.y,
    required this.dx,
    required this.dy,
    required String character,
    required super.color,
  }) : super(health: 1, character: character);

  @override
  void move(GameState state) {
    x += dx;
    y += dy;
  }
}
