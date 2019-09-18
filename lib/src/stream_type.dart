enum StreamType {
  observable, single, completable
}

class StreamTypeHandler {
  static StreamType valueOf(String value) {
    switch (value) {
      case "observable":
        return StreamType.observable;
      case "single":
        return StreamType.single;
      case "completable":
        return StreamType.completable;
    }

    throw Exception("Unable to evaluate StreamType value of: $value");
  }

  static String stringValue(StreamType type) {
    switch (type) {
      case StreamType.observable:
        return "observable";
      case StreamType.single:
        return "single";
      case StreamType.completable:
        return "completable";
    }
  }
}