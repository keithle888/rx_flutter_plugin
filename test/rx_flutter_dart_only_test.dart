import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rx_flutter_plugin/stream_type.dart';
import 'package:rx_flutter_plugin/rx_flutter_method_channel.dart';
import 'package:rx_flutter_plugin/exceptions.dart';
import 'dart:async';
import 'package:rx_flutter_plugin/field_names.dart';
import 'package:rx_flutter_plugin/observable_registration.dart';
import 'package:rx_flutter_plugin/observable_callback.dart';
import 'package:rx_flutter_plugin/utils.dart';

void main() {
  final String channel_name = "rx_flutter_plugin_dart_test";
  final RxFlutterMethodChannel channel = RxFlutterMethodChannel(channel_name);

  setUp(() {

  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

//  test('getPlatformVersion', () async {
//    expect(await RxFlutterPlugin.platformVersion, '42');
//  });

  test('testStreamTypes', () {
    final observableType = StreamType.observable;
        expect(StreamTypeHandler.stringValue(observableType), "observable");

    final singleType = StreamType.single;
    expect(StreamTypeHandler.stringValue(singleType), "single");

    final completableType = StreamType.completable;
    expect(StreamTypeHandler.stringValue(completableType), "completable");
  });

  test('testObservableRegistration_withSuccessfulResponse', () async {
    //Constants
    const String method = "testObservableRegistration_withSuccessfulResponse_method";

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case method:
          return {
            Field.ERROR_CODE: 0,
            Field.ERROR_MESSAGE: "None",
            Field.STREAM_TYPE: (methodCall.arguments as Map)[Field.STREAM_TYPE],
          };
      }
    });


    await channel.registerObservable(
      ObservableRegistrationRequest(
        method,
        StreamType.observable,
        Utils.generateRandomInt(),
        null
      )
    );
  });

  //TODO:: Need to fix test.
//  test('testObservableRegistration_withInvalidObservableTypeExceptionResponse', () async {
//    //Constants
//    const String method = "testObservableRegistration_withInvalidObservableTypeExceptionResponse";
//
//    channel.setMockMethodCallHandler((MethodCall methodCall) async {
//      switch (methodCall.method) {
//        case method:
//          return {
//            Field.ERROR_CODE: 2,
//            Field.ERROR_MESSAGE: "None",
//            Field.STREAM_TYPE: (methodCall.arguments as Map)[Field.STREAM_TYPE],
//          };
//      }
//    });
//
//    expect(
//        () async => await channel.registerObservable(
//            ObservableRegistrationRequest(
//              method,
//              StreamType.observable,
//              Utils.generateRandomInt(),
//              null
//            )
//        )
//    , throwsA(TypeMatcher<InvalidObservableTypeException>())
//    );
//  });

  test('testSingleRegistration_withPayload_successfullyReturns', () async {
    //Constants
    const String method = "testSingleRegistration_withPayload_successfullyReturns";
    final testData = {"someKey": "someValue"};

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case method:
          final requestId = (methodCall.arguments as Map)[Field.REQUEST_ID];
          final method = methodCall.method;
          //Send first onNext
          Timer(
              Duration(milliseconds: 300), () {
                channel.methodChannelCallback(
                    MethodCall(
                        method,
                        {
                          Field.OBSERVABLE_CALLBACK: ObservableCallbackTypeHandler.stringValue(ObservableCallbackType.onNext),
                          Field.REQUEST_ID: requestId,
                          Field.PAYLOAD: testData
                        })
            );
          });

          //Send onComplete
          Timer(
              Duration(milliseconds: 500), () {
            channel.methodChannelCallback(
                MethodCall(
                    method,
                    {
                      Field.OBSERVABLE_CALLBACK: ObservableCallbackTypeHandler.stringValue(ObservableCallbackType.onComplete),
                      Field.REQUEST_ID: requestId,
                    })
            );
          });

          return {
            Field.ERROR_CODE: 0,
            Field.ERROR_MESSAGE: "None",
          };
      }
    });


    expect(
        await channel.getSingle(
          method,
          testData
        ).first
        , testData
    );
  });

  test('testCompletableRegistration_immediatelyCompletes_successful', () async {
    //Constants
    const String method = "testCompletableRegistration_immediatelyCompletes_successful";

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case method:
          final requestId = (methodCall.arguments as Map)[Field.REQUEST_ID];
          final method = methodCall.method;
          Timer(
              Duration(milliseconds: 500), () {
                print("Timer done.");
                channel.methodChannelCallback(
                    MethodCall(
                        method,
                        {
                          Field.OBSERVABLE_CALLBACK: ObservableCallbackTypeHandler.stringValue(ObservableCallbackType.onComplete),
                          Field.REQUEST_ID: requestId
                        })
                );
              });

          return {
            Field.ERROR_CODE: 0,
          };
      }
    });

    final completableStream = channel.getCompletable(
        method,
        null
    );

    final itemsEmitted = await completableStream.length;
    print("itemsEmitted: $itemsEmitted");
    expect(itemsEmitted, 0);
  });

  test('testObservable_receive2ItemsThenComplete_success', () async {
    //Constants
    const String method = "testObservable_receive2ItemsThenComplete_success";
    final item1 = {"key1": "value1"};
    final item2 = {"key2": "value2"};

    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      switch (methodCall.method) {
        case method:
          final requestId = (methodCall.arguments as Map)[Field.REQUEST_ID];
          final method = methodCall.method;
          //Send first onNext
          Timer(
              Duration(milliseconds: 300), () {
            channel.methodChannelCallback(
                MethodCall(
                    method,
                    {
                      Field.OBSERVABLE_CALLBACK: ObservableCallbackTypeHandler.stringValue(ObservableCallbackType.onNext),
                      Field.REQUEST_ID: requestId,
                      Field.PAYLOAD: item1
                    })
            );
          });

          //Send second onNext
          Timer(
              Duration(milliseconds: 400), () {
            channel.methodChannelCallback(
                MethodCall(
                    method,
                    {
                      Field.OBSERVABLE_CALLBACK: ObservableCallbackTypeHandler.stringValue(ObservableCallbackType.onNext),
                      Field.REQUEST_ID: requestId,
                      Field.PAYLOAD: item2
                    })
            );
          });

          Timer(
              Duration(milliseconds: 500), () {
            print("Timer done.");
            channel.methodChannelCallback(
                MethodCall(
                    method,
                    {
                      Field.OBSERVABLE_CALLBACK: ObservableCallbackTypeHandler.stringValue(ObservableCallbackType.onComplete),
                      Field.REQUEST_ID: requestId
                    })
            );
          });

          return {
            Field.ERROR_CODE: 0,
          };
      }
    });

    final stream = channel.getObservable(
        method,
        null
    );

    final itemsEmitted = await stream.length;
    print("itemsEmitted: $itemsEmitted");
    expect(itemsEmitted, 2);
  });
}
