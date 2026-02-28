import 'package:nocterm/nocterm.dart';
import 'entity.dart';
import 'game_state.dart';
import 'constants.dart';

class FloatingText extends Entity {
  final int totalTicks = toTicks(0.8);
  int _ticksRemaining;
  final String text;
  final Color baseColor;

  FloatingText({
    required super.x,
    required super.y,
    required this.text,
    this.baseColor = const Color(0xFFFFFFFF),
  }) : _ticksRemaining = toTicks(0.8),
       super(health: 1, lines: [text], color: baseColor, zIndex: 100);

  @override
  void move(GameState state) {
    _ticksRemaining--;
    y -= perFrame(8.0); // Float up quickly (8 units per second)
    
    if (_ticksRemaining <= 0) {
      health = 0;
      state.removeEntity(this);
    }
  }

  @override
  Color? get color {
    final ratio = (_ticksRemaining / totalTicks).clamp(0.0, 1.0);
    // Since terminal rendering often ignores alpha, we manually blend with black
    return Color.fromRGB(
      (baseColor.red * ratio).toInt().clamp(0, 255),
      (baseColor.green * ratio).toInt().clamp(0, 255),
      (baseColor.blue * ratio).toInt().clamp(0, 255),
    );
  }
}
