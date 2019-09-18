import 'dart:async';
import 'stream_type.dart';

class ObservableStreamController<T> {
  StreamController<T> _controller;
  StreamType _type;

  ObservableStreamController._();
  ObservableStreamController(
      StreamType type,
      {void onListen(),
        onCancel(),
        bool sync: false}
      ) {
    this._type = type;
    this._controller = StreamController(
      onListen: onListen,
      onCancel: onCancel
    );
  }

  Stream<T> stream() {
    return _controller.stream;
  }

  void add(T event) {
    //Add depending on type
   switch (_type) {
     case StreamType.observable:
       _controller.add(event);
       break;
     case StreamType.single:
       _controller.add(event);
       _controller.close();
       break;
     case StreamType.completable:
       throw FormatException("Completable is not supposed to receive an onNext. Please fix.");
       break;
   }
  }

  void close() {
    _controller.close();
  }

  void addError(Exception exception, [StackTrace stacktrace]) {
    _controller.addError(exception, stacktrace);
  }
}