/**
 Used to convert Errors from Rx subscriptions to payloads that can be deserialized on Dart.
 */
public protocol ErrorHandler {
    /**
     * Return must conform to Flutter Platform Channels supported data types.
     * https://flutter.dev/docs/development/platform-integration/platform-channels
     */
    func handleError(error: Error) -> Any?
}
