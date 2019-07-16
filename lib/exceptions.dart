class InvalidObservableTypeException implements Exception {
  String cause;
  InvalidObservableTypeException([String cause]) {
    this.cause = cause;
  }

  @override
  String toString() {
    if (cause == null) return "Exception";
    return "Exception: $cause";
  }
}

class ObservableStateException implements Exception {
  String cause;
  ObservableStateException([String cause]) {
    this.cause = cause;
  }

  @override
  String toString() {
    if (cause == null) return "Exception";
    return "Exception: $cause";
  }
}

class ObservableNotAvailableException implements Exception {
  String cause;
  ObservableNotAvailableException([String cause]) {
    this.cause = cause;
  }

  @override
  String toString() {
    if (cause == null) return "Exception";
    return "Exception: $cause";
  }
}

///Exception thrown by the observable.
class ObservableThrownException implements Exception {
  String cause;
  dynamic payload;
  ObservableThrownException([
    String cause,
    dynamic payload
  ]) {
    this.cause = cause;
    this.payload = payload;
  }

  @override
  String toString() {
    if (cause == null) return "Exception";
    return "Exception: $cause, payload: $payload";
  }
}

class RxFlutterPluginExceptionHandler {
  RxFlutterPluginExceptionHandler._();

  static Exception getException(int errorCode, String message, [dynamic payload]) {
    switch (errorCode) {
      case 1:
        return new InvalidObservableTypeException(message);
      case 2:
        return new ObservableStateException(message);
      case 3:
        return new ObservableNotAvailableException(message);
      case 4:
        return new ObservableThrownException(message, payload);
    }
    throw new Exception("Unknown errorCode: $errorCode. Unable to create custom exception.");
  }
}