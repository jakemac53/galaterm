import 'package:nocterm/nocterm.dart';
import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';
import 'player.dart';

enum ItemType { money, bomb, shield, speedBoost, rapidFire }

class Item extends Entity {
  final ItemType type;

  Item({required super.x, required super.y, required this.type})
    : super(health: 1, character: _getChar(type), color: _getColor(type));

  static String _getChar(ItemType type) {
    switch (type) {
      case ItemType.money:
        return r'$';
      case ItemType.bomb:
        return 'B';
      case ItemType.shield:
        return 'S';
      case ItemType.speedBoost:
        return '>';
      case ItemType.rapidFire:
        return '!';
    }
  }

  static Color _getColor(ItemType type) {
    switch (type) {
      case ItemType.money:
        return const Color(0xFFFFD700);
      case ItemType.bomb:
        return const Color(0xFFFF4500);
      case ItemType.shield:
        return const Color(0xFF00FF00);
      case ItemType.speedBoost:
        return const Color(0xFF1E90FF);
      case ItemType.rapidFire:
        return const Color(0xFFFF00FF);
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
