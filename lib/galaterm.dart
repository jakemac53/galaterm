import 'dart:async';
import 'package:nocterm/nocterm.dart';

import 'entity.dart';
import 'game_state.dart';
import 'player.dart';

class GalatermApp extends StatefulComponent {
  const GalatermApp({super.key});

  @override
  State<GalatermApp> createState() => _GalatermAppState();
}

class _GalatermAppState extends State<GalatermApp> {
  late GameState _gameState;
  late Player _player;
  Timer? _gameLoop;

  final int _width = 80;
  final int _height = 40;

  @override
  void initState() {
    super.initState();
    _gameState = GameState();
    _player = Player(x: 40, y: 20);
    _gameState.addEntity(_player);
    // Initialize the entities immediately so they render on frame 1
    _gameState.tick();

    _gameLoop = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _gameState.tick();
      });
    });
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // We create a lookup map to quickly find entities by their (x, y) coordinates.
    // In a sparse grid, this is much faster than iterating over entities on every cell rendering.
    final entityMap = <String, Entity>{};
    for (final e in _gameState.entities) {
      entityMap['${e.x},${e.y}'] = e;
    }

    return NoctermApp(
      title: 'Galaterm',
      child: Focusable(
        focused: true,
        onKeyEvent: (event) {
          if (event.character?.toLowerCase() == 'q') {
            shutdownApp();
            return true;
          }
          if (event.logicalKey == LogicalKey.space || event.character == ' ') {
            _player.fire(_gameState);
            return true;
          }
          return false;
        },
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              border: BoxBorder.all(style: BoxBorderStyle.rounded),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(_height, (y) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_width, (x) {
                        final entity = entityMap['$x,$y'];
                        return MouseRegion(
                          onHover: (event) {
                            if (_player.x != x || _player.y != y) {
                              _player.moveTo(x, y);
                              // We don't need a hard setState here instantly since the game loop
                              // re-renders every 100ms anyway, but for ultra responsiveness:
                              setState(() {});
                            }
                          },
                          onEnter: (event) {
                            if (_player.x != x || _player.y != y) {
                              _player.moveTo(x, y);
                              setState(() {});
                            }
                          },
                          child: Text(
                            entity?.character ?? ' ',
                            style: TextStyle(color: entity?.color),
                          ),
                        );
                      }),
                    );
                  }),
                  const SizedBox(height: 1),
                  const Text(
                    'Use mouse to move. Press "q" to quit.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
