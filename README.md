# RxFlutterPlugin

A flutter plugin to bridge RxJava &amp; RxSwift to Dart streams.

## Getting Started

Add this plugin to your flutter application through your pubspec.yaml
````
dependencies:
    rx_flutter_plugin: ^x.y.z
````


## Opening a platform channel
Flutter
```
final channel = new RxFlutterMethodChannel("custom_channel_name");
```

Android (Kotlin)
```
val channel = RxFlutterMethodChannel("custom_channel_name", binaryMesseger)
//You can pass in anything that extends FlutterActivity for the binaryMessenger argument. Will be removed in future releases.
```

## Connection your observables
*Note: All arguments and return values from observables must follow the supported data types for [platform channels](https://flutter.dev/docs/development/platform-integration/platform-channels).

### Observables

Android
```
channel.addObservable<T>(
                "method_A",
                { argumentsFromFlutter: T ->
                    //Return an ObservableSource<*>
                    return@addObservable Observable.just(1)
                }
        )
```

Flutter
```
channel.getObservable(
    "method_A",
    {
        "argument_key_1": "argument_value_1"
    }
)
```

### Singles
Android
```
channel.addSingle<T>(
                "method_b",
                { argumentsFromFlutter: T ->
                    //Return a SingleSource<*>
                    return@addSingle Single.just(1)
                }
        )
```

Flutter
```
channel.getSingle(
    "method_B",
    {
        "argument_key_1": "argument_value_1"
    }
)
```

### Completables
Android
```
channel.addCompletable<T>(
                "method_C",
                { argumentsFromFlutter: T ->
                    //Return a CompletableSource
                    return@addCompletable Completable.complete()
                }
        )
```

Flutter
```
channel.getCompletable(
    "method_C",
    {
        "argument_key_1": "argument_value_1"
    }
)
```

## Error Propagation
How to handle exceptions / errors thrown from the native platforms.
When adding the observable source, the errorHandler parameter allows you to pass in a block that accepts a Throwable/Error argument and convert that into a payload (needs to conform to supported data types) that will be a member variable of the ObservableThrownException thrown in Dart. 

Android
```
channel.addCompletable<T>(
                "method_C",
                { argumentsFromFlutter: T ->
                    //Return a CompletableSource
                    return@addCompletable Completable.complete()
                }, 
                { t: Throwable ->
                    return@addObservable hashMapOf(
                            "errorMessage" to t.message
                    )
                }
        )
```
