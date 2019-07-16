class RxPluginLogger {
  static bool enabled = false;

  String tag;
  RxPluginLogger._();
  RxPluginLogger(String tag) {
    this.tag = tag;
  }

  void d(String message, [Exception exception, StackTrace stacktrace]) {
    if (enabled) {
      _printLog(_Level.debug, tag, message, exception, stacktrace);
    }
  }

  void w(String message, [Exception exception, StackTrace stacktrace]) {
    if (enabled) {
      _printLog(_Level.warning, tag, message, exception, stacktrace);
    }
  }

  void i(String message, [Exception exception, StackTrace stacktrace]) {
    if (enabled) {
      _printLog(_Level.info, tag, message, exception, stacktrace);
    }
  }

  void e(String message, [Exception exception, StackTrace stacktrace]) {
    if (enabled) {
      _printLog(_Level.error, tag, message, exception, stacktrace);
    }
  }

  static void _printLog(_Level level, String tag, String message, [Exception exception, StackTrace stacktrace]) {
    print("~RxFlutterPlugin~$tag/${_asString(level)}: $message");
    if (exception != null) {
      print("\tException: ${exception.toString()}");
      if (stacktrace != null) {
        print("\t\tStacktrace: ${stacktrace.toString()}");
      }
    }
  }

  static String _asString(_Level level) {
    switch (level) {
      case _Level.debug:
        return "D";
      case _Level.error:
        return "E";
      case _Level.info:
        return "I";
      case _Level.warning:
        return "W";
    }
  }
}

enum _Level {
  debug, warning, info, error
}