import 'stream_type.dart';
import 'observable_action.dart';
import 'package:flutter/services.dart';
import 'field_names.dart';
import 'exceptions.dart';
import 'logger.dart';

final _log = RxPluginLogger("ObservableRegistration");

class ObservableRegistrationRequest {
  String channel;
  String method;
  StreamType streamType;
  int requestId;
  dynamic arguments;
  ObservableAction oa;

  ObservableRegistrationRequest._();
  ObservableRegistrationRequest(
      String method,
      StreamType streamType,
      int requestId,
      dynamic arguments,
      [ObservableAction oa]
      ) {
    this.method = method;
    this.streamType = streamType;
    this.requestId = requestId;
    this.arguments = arguments;
    this.oa = oa;
  }

  Future<ObservableRegistrationResponse> invokeObservableRegistration(
      MethodChannel channel
      ) async {
    _log.d("Platform channel request: $this");
    final response = await channel.invokeMethod(
        this.method,
        {
          Field.STREAM_TYPE: StreamTypeHandler.stringValue(this.streamType),
          Field.METHOD: this.method,
          Field.PAYLOAD: this.arguments,
          Field.REQUEST_ID: this.requestId,
          Field.OBSERVABLE_ACTION: ObservableActionHandler.stringValue(this.oa)
        }
    ) as Map;
    _log.d("Platform channel response: $response");
    //Cast back to Observable Registration Response
    final orResponse = ObservableRegistrationResponse(response);
    return orResponse;
  }

  @override
  String toString() {
    return "ObservableRegistrationRequest {" +
        "method: $method, " +
        "streamType: ${StreamTypeHandler.stringValue(streamType)}, " +
        "requestId: $requestId, " +
        "arguments: $arguments, " +
        "observableAction: $oa" +
        "}";
  }
}

class ObservableRegistrationResponse {
  int errorCode;
  String errorMessage;

  ObservableRegistrationResponse(
      Map<dynamic, dynamic> map
      ) {
    this.errorCode = map[Field.ERROR_CODE];
    this.errorMessage = map[Field.ERROR_MESSAGE];
    if (errorCode == null) {
      throw FormatException("errorCode response returned is null. It should be null, please fix.");
    }
  }
}