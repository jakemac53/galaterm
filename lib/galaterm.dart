import 'package:nocterm/nocterm.dart';

class GalatermApp extends StatefulComponent {
  const GalatermApp({super.key});

  @override
  State<GalatermApp> createState() => _GalatermAppState();
}

class _GalatermAppState extends State<GalatermApp> {
  int _playerX = 40;
  int _playerY = 20;

  final int _width = 80;
  final int _height = 40;

  @override
  Component build(BuildContext context) {
    return NoctermApp(
      title: 'Galaterm',
      child: Focusable(
        focused: true,
        onKeyEvent: (event) {
          if (event.character?.toLowerCase() == 'q') {
            shutdownApp();
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
                        final isPlayer = (x == _playerX && y == _playerY);
                        return MouseRegion(
                          onHover: (event) {
                            if (_playerX != x || _playerY != y) {
                              setState(() {
                                _playerX = x;
                                _playerY = y;
                              });
                            }
                          },
                          // We also use onEnter just to be sure we catch the initial grid entry
                          onEnter: (event) {
                            if (_playerX != x || _playerY != y) {
                              setState(() {
                                _playerX = x;
                                _playerY = y;
                              });
                            }
                          },
                          child: Text(isPlayer ? '▲' : ' '),
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
