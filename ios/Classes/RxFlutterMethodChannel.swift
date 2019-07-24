import Flutter
import RxSwift

public class RxFlutterPluginMethodChannel {
    let methodChannel: FlutterMethodChannel
    
    var cachedDisposables: [Int: Disposable] = [:]
    var storedObservables: [String: ObservableSourceHolder<Any>] = [:]
    
    init(
        _ channelName: String,
        _ binaryMessenger: FlutterBinaryMessenger
        ) {
        self.methodChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: binaryMessenger
        )
        
        methodChannel.setMethodCallHandler{ (methodCall: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            RxFlutterPluginLogger.d("onMethodCall = channel: \(channelName), method: \(methodCall.method), arguments: \(methodCall.arguments)")
            
            //Attempt to cast to ObservableRegistrationRequest
            do {
                let observableRegistration = try ObservableRegistrationRequest(methodCall)
                switch observableRegistration.observableAction {
                case ObservableAction.SUBSCRIBE:
                    let observableSource = self.storedObservables[observableRegistration.method]
                    if observableSource == nil
                    {
                        result(
                            ObservableRegistrationResponse(
                                errorCode: PluginError.getErrorCode(PluginError.ObservableNotAvailable(nil)),
                                errorMessage: "Could not find source for \(observableRegistration.method)"
                                ).toDictionary()
                        )
                    }
                    else
                    {
                        if observableRegistration.streamType != observableSource!.type {
                            result(
                                ObservableRegistrationResponse(
                                    errorCode: PluginError.getErrorCode(PluginError.InvalidObservableType(nil)),
                                    errorMessage: "Expected \(observableRegistration.streamType.rawValue) but found \(observableSource!.type.rawValue)"
                                    )
                                    .toDictionary()
                            )
                        }
                        else
                        {
                            do
                            {
                                self.subscribeToSource(
                                    requestId: observableRegistration.requestId,
                                    source: observableSource!,
                                    arguments: observableRegistration.arguments
                                )
                                result(
                                    ObservableRegistrationResponse(
                                        errorCode: 0,
                                        errorMessage: nil
                                        )
                                        .toDictionary()
                                )
                            }
                            catch
                            {
                                result(
                                    ObservableRegistrationResponse(
                                        errorCode: PluginError.getErrorCode(PluginError.ObservableState(nil)),
                                        errorMessage: error.localizedDescription
                                        )
                                        .toDictionary()
                                )
                            }
                        }
                    }
                    
                case ObservableAction.DISPOSE:
                    let cachedDisposable = self.cachedDisposables.removeValue(forKey: observableRegistration.requestId)
                    if cachedDisposable == nil {
                        RxFlutterPluginLogger.w("Could not find subscribed observable for requestId \(observableRegistration.requestId)}")
                        result(
                            ObservableRegistrationResponse(
                                errorCode: 0,
                                errorMessage: nil
                                )
                                .toDictionary()
                        )
                    }
                    else
                    {
                        cachedDisposable?.dispose()
                        result(
                            ObservableRegistrationResponse(
                                errorCode: 0,
                                errorMessage: nil
                                )
                                .toDictionary()
                        )
                    }
                }
            } catch {
                RxFlutterPluginLogger.e("Encountered an error trying to handle methodCall.", error)
            }
        }
    }
    
    private func subscribeToSource(
        requestId: Int,
        source: ObservableSourceHolder<Any>,
        arguments: Any?
        )
    {
        switch source.type {
        case StreamType.OBSERVABLE:
            cachedDisposables[requestId] = Observable.deferred {
                return source.getSourceAsObservable(arguments)
                }
                .subscribe(
                    onNext: { element in
                        RxFlutterPluginLogger.d("onNext = requestId: \(requestId), payload: \(element)")
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_NEXT,
                                requestId: requestId,
                                payload: element,
                                errorMessage: nil
                            )
                        )
                },
                    onError: { error in
                        RxFlutterPluginLogger.d("onError = requestId: \(requestId), error: \(error)")
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_ERROR,
                                requestId: requestId,
                                payload: source.errorHandler?(error),
                                errorMessage: error.localizedDescription
                            )
                        )
                },
                    onCompleted: {
                        RxFlutterPluginLogger.d("onCompleted = requestId: \(requestId)")
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_COMPLETE,
                                requestId: requestId,
                                payload: nil,
                                errorMessage: nil
                            )
                        )
                }
            )
        case StreamType.SINGLE:
            cachedDisposables[requestId] = Single.deferred {
                return source.getSourceAsSingle(arguments)
                }
                .subscribe(
                    onSuccess: { element in
                        RxFlutterPluginLogger.d("onSuccess = requestId: \(requestId), payload: \(element)")
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_NEXT,
                                requestId: requestId,
                                payload: element,
                                errorMessage: nil
                            )
                        )
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_COMPLETE,
                                requestId: requestId,
                                payload: nil,
                                errorMessage: nil
                            )
                        )
                },
                    onError: { error in
                        RxFlutterPluginLogger.d("onError = requestId: \(requestId), error: \(error)")
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_ERROR,
                                requestId: requestId,
                                payload: source.errorHandler?(error),
                                errorMessage: error.localizedDescription
                            )
                        )
                }
            )
        case StreamType.COMPLETABLE:
            cachedDisposables[requestId] = Completable.deferred {
                return source.getSourceAsCompletable(arguments)
                }
                .subscribe(
                    onCompleted: {
                        RxFlutterPluginLogger.d("onCompleted = requestId: \(requestId)")
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_COMPLETE,
                                requestId: requestId,
                                payload: nil,
                                errorMessage: nil
                            )
                        )
                },
                    onError: { error in
                        RxFlutterPluginLogger.d("onError = requestId: \(requestId), error: \(error)")
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_ERROR,
                                requestId: requestId,
                                payload: source.errorHandler?(error),
                                errorMessage: error.localizedDescription
                            )
                        )
                }
            )
        }
    }
    
    private func sendObservableCallback(_ observableCallback: ObservableCallback) {
        RxFlutterPluginLogger.d("sendObservableCallback(): \(observableCallback)")
        DispatchQueue.main.async {
            self.methodChannel.invokeMethod(
                "callback",
                arguments: NSDictionary(dictionary: [
                    Field.OBSERVABLE_CALLBACK: observableCallback.callbackType.rawValue,
                    Field.PAYLOAD: observableCallback.payload,
                    Field.REQUEST_ID: observableCallback.requestId,
                    Field.ERROR_MESSAGE: observableCallback.errorMessage
                ])
            )
        }
    }
}
