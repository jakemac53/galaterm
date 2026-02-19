const double fps = 60.0;

/// Scales a value (e.g. speed in units per second) to units per frame
/// based on the global [fps].
double perFrame(num unitsPerSecond) => unitsPerSecond / fps;

/// Scales an interval (e.g. cooldown in seconds) to ticks per frame
/// based on the global [fps].
int toTicks(num seconds) => (seconds * fps).round();
