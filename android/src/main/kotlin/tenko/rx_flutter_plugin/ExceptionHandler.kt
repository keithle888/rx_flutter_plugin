package tenko.rx_flutter_plugin

/**
 * Used to convert throwables from Rx subscriptions to payloads that can be deserialized on Dart.
 */
abstract class ExceptionHandler {
    /**
     * Return must conform to Flutter Platform Channels supported data types.
     * https://flutter.dev/docs/development/platform-integration/platform-channels
     */
    abstract fun handleException(throwable: Throwable): Any?
}