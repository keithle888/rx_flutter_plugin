
abstract class ExceptionHandler {
  ///Called when ObservableThrownException is returned by the native platform.
  ///Return null if the payload is not what is expected. If null is provided, the plugin will thrown ObservableThrownException.
  Exception onError(dynamic payload);
}