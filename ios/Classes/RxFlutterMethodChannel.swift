import Flutter
import RxSwift

public class RxFlutterPluginMethodChannel {
    let methodChannel: FlutterMethodChannel
    
    var cachedDisposables: [Int: Disposable] = [:]
    var storedObservables: [String: ObservableSourceHolder] = [:]
    
    public init(
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
    
    public func addObservable(
        _ method: String,
        _ sourceGen: @escaping (Any?) throws -> Observable<Any>,
        _ errorHandler: ((Error) -> Any?)?
        ) {
        let existingObservable = storedObservables.removeValue(forKey: method)
        if existingObservable != nil {
            RxFlutterPluginLogger.w("Removing existing observable source for method: \(method)")
        }
        storedObservables[method] = ObservableSourceHolderImpl(
            observable: sourceGen,
            errorHandler
            )
        RxFlutterPluginLogger.d("Added observable source for method: \(method)")
    }
    
    public func addSingle(
        _ method: String,
        _ sourceGen: @escaping (Any?) throws -> PrimitiveSequence<SingleTrait, Any>,
        _ errorHandler: ((Error) -> Any?)?
        ) {
        let existingObservable = storedObservables.removeValue(forKey: method)
        if existingObservable != nil {
            RxFlutterPluginLogger.w("Removing existing single source for method: \(method)")
        }
        storedObservables[method] = ObservableSourceHolderImpl(
            single: sourceGen,
            errorHandler
            )
        RxFlutterPluginLogger.d("Added single source for method: \(method)")
    }
    
    public func addCompletable(
        _ method: String,
        _ sourceGen: @escaping (Any?) throws -> PrimitiveSequence<CompletableTrait, Never>,
        _ errorHandler: ((Error) -> Any?)?
        ) {
        let existingObservable = storedObservables.removeValue(forKey: method)
        if existingObservable != nil {
            RxFlutterPluginLogger.w("Removing existing completable source for method: \(method)")
        }
        storedObservables[method] = ObservableSourceHolderImpl(
            completable: sourceGen,
            errorHandler
            )
        RxFlutterPluginLogger.d("Added completable source for method: \(method)")
    }
    
    private func subscribeToSource(
        requestId: Int,
        source: ObservableSourceHolder,
        arguments: Any?
        )
    {
        switch source.type {
        case StreamType.OBSERVABLE:
            cachedDisposables[requestId] = Observable.deferred {
                return try source.getSourceAsObservable(arguments)
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
                return try source.getSourceAsSingle(arguments)
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
                return try source.getSourceAsCompletable(arguments)
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
                    Field.OBSERVABLE_CALLBACK.rawValue: observableCallback.callbackType.rawValue,
                    Field.PAYLOAD.rawValue: observableCallback.payload,
                    Field.REQUEST_ID.rawValue: observableCallback.requestId,
                    Field.ERROR_MESSAGE.rawValue: observableCallback.errorMessage
                ])
            )
        }
    }
}
