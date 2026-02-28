import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';
import 'player.dart';

enum ItemType { money, bomb, shield, speedBoost, rapidFire }

class Item extends Entity {
  final ItemType type;

  Item({required super.x, required super.y, required this.type})
    : super(
        health: 1,
        character: _getChar(type),
        zIndex: 20,
      );

  static String _getChar(ItemType type) {
    switch (type) {
      case ItemType.money:
        return '💰';
      case ItemType.bomb:
        return '🧨'; // Red dynamite is more visible than 💣 on black
      case ItemType.shield:
        return '🛡️';
      case ItemType.speedBoost:
        return '⚡'; // Lightning is high contrast
      case ItemType.rapidFire:
        return '🔥';
    }
  }

  @override
  void move(GameState state) {
    y += perFrame(5.0);
    if (y >= state.height) {
      state.removeEntity(this);
    }
  }

  @override
  void collide(GameState state, Map<int, Map<int, List<Entity>>> grid) {
    final list = grid[gridX]?[gridY];
    if (list != null) {
      for (final e in list) {
        if (e is Player) {
          e.collect(this, state);
          state.removeEntity(this);
          return;
        }
      }
    }
  }
}
