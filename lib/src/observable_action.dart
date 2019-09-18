enum ObservableAction {
  subscribe, dispose
}

class ObservableActionHandler {
  static ObservableAction valueOf(String value) {
    switch (value) {
      case "subscribe":
        return ObservableAction.subscribe;
      case "dispose":
        return ObservableAction.dispose;
    }
    throw Exception("Unable to derive ObservableAction from value of: $value");
  }

  static String stringValue(ObservableAction oa) {
    switch (oa) {
      case ObservableAction.subscribe:
        return "subscribe";
      case ObservableAction.dispose:
        return "dispose";
    }
  }
}