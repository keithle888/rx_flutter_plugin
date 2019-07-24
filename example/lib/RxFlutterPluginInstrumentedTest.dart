import 'package:flutter/material.dart';
import 'package:rx_flutter_plugin/rx_flutter_method_channel.dart';
import 'dart:io';
import 'dart:async';

void main() async {

  testSingle_returns1();

  completableCompletes();

  testObservable_returnsIncreasingInts_success();

  runApp(MainWidget());
}

class MainWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Plugin Instrumented Testing",
      home: Scaffold(
        appBar: AppBar(
          title: Text("Plugin Instrumented Testing"),
        ),
      ),
    );
  }
}


void testObservable_returnsIncreasingInts_success() {
  final channel = RxFlutterMethodChannel("rx_flutter_plugin");
  channel.getObservable("testObservable_returnsIncreasingInts_success", null)
      .listen(
          (response) {
        print(response as int);
      },
      onDone: () {
        print("done");
      },
      onError: (error) {
        print("error: $error");
      }
  );
}

void completableCompletes() async {
  final channel = RxFlutterMethodChannel("rx_flutter_plugin");
  await channel.getCompletable("testCompletable_success", null).length == 0;
}

void testSingle_returns1() async {
  final channel = RxFlutterMethodChannel("rx_flutter_plugin");
  await channel.getSingle("testSingle_returns1", null).first == 1;
}
//void completableThrowsError() async {
//  final channel = RxFlutterMethodChannel("rx_flutter_plugin");
//  await channel.getCompletable("testCompletable_withError", null).first.catchError(onError);
//}