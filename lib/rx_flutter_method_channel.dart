import 'package:flutter/services.dart';
import 'stream_type.dart';
import 'exceptions.dart';
import 'dart:async';
import 'utils.dart';
import 'observable_action.dart';
import 'observable_registration.dart';
import 'observable_callback.dart';
import 'observable_stream_controller.dart';
import 'logger.dart';
final _log = RxPluginLogger("RxFlutterMethodChannel");

///A helper class from easily binding ReactiveX observable types on the native platforms to the dart streams.
///Special methods that are not usable are "initializeRxFlutterPluginChannel"
class RxFlutterMethodChannel {
  MethodChannel _channel;


  RxFlutterMethodChannel(
      String channelName,
      ) {
    this._channel = MethodChannel(channelName);
    _channel.setMethodCallHandler(methodChannelCallback);
  }

  void setMockMethodCallHandler(Future<dynamic> handler(MethodCall call)) {
    _channel.setMockMethodCallHandler(handler);
  }

  ///Always return null.
  Future<dynamic> methodChannelCallback(MethodCall call) {
    _log.d("onMethodCall: ${call.method}, arguments: ${call.arguments}");
    final args = call.arguments as Map;
    //Cast to ObservableCallback
    ObservableCallback callback;
    try {
      callback = ObservableCallback(args);
    } catch (e, stack) {
      _log.w("Failed to cast MethodCall.arguments to an ObservableCallback. Skipping callback processing.", e, stack);
      return null;
    }

    final streamController = cachedStreams[callback.requestId];
    if (streamController == null) {
      _log.w("Unable to find streamController for requestId ${callback.requestId}. Unable to proceed with processing MethodCall");
      return null;
    }

    switch (callback.type) {
      case ObservableCallbackType.onNext:
        streamController.add(callback.payload);
        break;
      case ObservableCallbackType.onComplete:
        streamController.close();
        break;
      case ObservableCallbackType.onError:
        streamController.addError(
          new ObservableThrownException(
            callback.errorMessage,
            callback.payload
          )
        );
        streamController.close();
        break;
    }
    return null;
  }
  
  ///Calling pause/resume will not work on these streams.
  Stream<dynamic> getObservable(
      String method,
      [dynamic arguments]
      ) {
    final requestId = Utils.generateRandomInt();
    final streamController = createSteamController(method, requestId, arguments, StreamType.observable);
    return streamController.stream();
  }

  ///Calling pause/resume will not work on these streams.
  ///onData will be called once followed by onDone.
  Stream<dynamic> getSingle(
      String method,
      [dynamic arguments]
      ) {
    final requestId = Utils.generateRandomInt();
    final streamController = createSteamController(method, requestId, arguments, StreamType.single);
    return streamController.stream();
  }

  ///Calling pause/resume will not work on these streams.
  ///Only either onDone will be called or onError follow by onDone.
  Stream<void> getCompletable(
      String method,
      [dynamic arguments]
      ) {
    final requestId = Utils.generateRandomInt();
    final streamController = createSteamController(method, requestId, arguments, StreamType.completable);
    return streamController.stream();
  }

  ///Try not to use this function, instead
  Future<void> registerObservable(ObservableRegistrationRequest request) async {
    final response = await request.invokeObservableRegistration(_channel);
    if (response.errorCode != 0) {
      throw RxFlutterPluginExceptionHandler.getException(response.errorCode, response.errorMessage);
    }
  }

  ///Used to hold stream controllers for callbacks from the observables on the native side.
  static final Map<int, ObservableStreamController<dynamic>> cachedStreams = {};
  
  ObservableStreamController<dynamic> createSteamController(
      String method,
      int requestId,
      dynamic arguments,
      StreamType streamType
      ) {
    ObservableStreamController<dynamic> streamController;
    streamController = new ObservableStreamController(
        streamType,
        onListen: () async {
          //Send observable registration
          final _ = await registerObservable(
              ObservableRegistrationRequest(
                method,
                streamType,
                requestId,
                arguments,
                ObservableAction.subscribe
              )
          );
        },
        onCancel: () async {
          //Remove StreamController from cachedStreams
          removeStreamController(requestId);

          //Dispose of observable
          final _ = await registerObservable(
              ObservableRegistrationRequest(
                method,
                streamType,
                requestId,
                null,
                ObservableAction.dispose
              )
          );
        }
    );

    //Store StreamController in cachedStreams first.
    cachedStreams[requestId] = streamController;
    
    return streamController;
  }

  //TODO::Create tests for 1) incorrect onNext for completable, 2) checking for disposing, 3) oncorrect callback sequence
  
  void removeStreamController(int requestId) {
    if (!cachedStreams.containsKey(requestId)) {
      _log.w("Stream controller to be removed from cachedStreams was not found. Unexpected state.");
    } else {
      cachedStreams.remove(requestId);
    }
  }


  ///Clears all pending resources
  void close() {
    cachedStreams.forEach((key, controller) {
      controller.close();
    });
  }
}
