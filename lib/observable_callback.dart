import 'field_names.dart';

enum ObservableCallbackType {
  onNext, onComplete, onError
}

class ObservableCallbackTypeHandler {
  static ObservableCallbackType valueOf(String value) {
    switch (value) {
      case "onNext":
        return ObservableCallbackType.onNext;
      case "onComplete":
        return ObservableCallbackType.onComplete;
      case "onError":
        return ObservableCallbackType.onError;
    }
    throw Exception("Unable to derive ObservableCallback from value of: $value");
  }

  static String stringValue(ObservableCallbackType oc) {
    switch (oc) {
      case ObservableCallbackType.onError:
        return "onError";
      case ObservableCallbackType.onComplete:
        return "onComplete";
      case ObservableCallbackType.onNext:
        return "onNext";
    }
  }
}

class ObservableCallback {
  ObservableCallbackType type;
  int requestId;
  dynamic payload;

  //Error from observable
  String errorMessage;

  ObservableCallback(
      Map<dynamic, dynamic> map
      ) {
    this.type = ObservableCallbackTypeHandler.valueOf(
        map[Field.OBSERVABLE_CALLBACK]
    );
    this.requestId = map[Field.REQUEST_ID];
    this.payload = map[Field.PAYLOAD];
    this.errorMessage = map[Field.ERROR_MESSAGE];

    //Validation
    if (type == null) {
      throw FormatException("Callback type should not be null. Please fix.");
    }
    if (requestId == null) {
      throw FormatException("requestId should not be null. Please fix.");
    }
  }
}