import 'package:flutter/services.dart';
import 'package:rx_flutter_plugin/rx_flutter_plugin.dart';
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
    _channel.setMethodCallHandler(_methodChannelCallback);
  }

  /// For debugging responses from native.
  void setMockMethodCallHandler(Future<dynamic> handler(MethodCall call)) {
    _channel.setMockMethodCallHandler(handler);
  }

  /// Always return null.
  Future<dynamic> _methodChannelCallback(MethodCall call) {
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
        Exception exceptionToThrow = _defaultExceptionHandler?.onError(callback.payload) ??
            ObservableThrownException(callback.errorMessage, callback.payload);
        streamController.addError(
            exceptionToThrow
        );
        streamController.close();
        break;
    }
    return null;
  }
  
  /// Calling pause/resume will not work on these streams.
  Stream<dynamic> getObservable(
      String method,
      [dynamic arguments]
      ) {
    final requestId = Utils.generateRandomInt();
    final streamController = _createSteamController(method, requestId, arguments, StreamType.observable);
    return streamController.stream();
  }

  /// Calling pause/resume will not work on these streams.
  /// onData will be called once followed by onDone.
  Stream<dynamic> getSingle(
      String method,
      [dynamic arguments]
      ) {
    final requestId = Utils.generateRandomInt();
    final streamController = _createSteamController(method, requestId, arguments, StreamType.single);
    return streamController.stream();
  }

  /// Calling pause/resume will not work on these streams.
  /// Only either onDone will be called or onError follow by onDone.
  Stream<void> getCompletable(
      String method,
      [dynamic arguments]
      ) {
    final requestId = Utils.generateRandomInt();
    final streamController = _createSteamController(method, requestId, arguments, StreamType.completable);
    return streamController.stream();
  }

  ///
  Future<void> _subscribeToObservable(ObservableRegistrationRequest request) async {
    final response = await request.invokeObservableRegistration(_channel);
    if (response.errorCode != 0) {
      throw RxFlutterPluginExceptionHandler.getException(response.errorCode, response.errorMessage);
    }
  }

  /// Used to hold stream controllers for callbacks from the observables on the native side.
  static final Map<int, ObservableStreamController<dynamic>> cachedStreams = {};
  
  ObservableStreamController<dynamic> _createSteamController(
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
          final _ = await _subscribeToObservable(
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
          _removeStreamController(requestId);

          //Dispose of observable
          final _ = await _subscribeToObservable(
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

    // Store StreamController in cachedStreams first.
    cachedStreams[requestId] = streamController;
    
    return streamController;
  }


  void _removeStreamController(int requestId) {
    if (!cachedStreams.containsKey(requestId)) {
      _log.w("Stream controller to be removed from cachedStreams was not found. Unexpected state.");
    } else {
      cachedStreams.remove(requestId);
    }
  }


  /// Clears all existing observable subscriptions
  void close() {
    cachedStreams.forEach((key, controller) {
      controller.close();
    });
  }

  ExceptionHandler _defaultExceptionHandler = null;

  /// Default error handler when an ObservableThrownException is thrown from native.
  void setDefaultExceptionHandler(ExceptionHandler exceptionHandler) {
    _defaultExceptionHandler = exceptionHandler;
  }
}
