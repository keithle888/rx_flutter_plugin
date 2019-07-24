package tenko.rx_flutter_plugin_example

import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
  lateinit var testingChannel: RxFlutterTestingChannel
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)
    testingChannel = RxFlutterTestingChannel(this.flutterView)
  }
}
