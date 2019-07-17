import RxSwift
import Flutter

class RxFlutterMethodChannel {
    let methodChannel: FlutterMethodChannel
    
//    let methodCallHandler: FlutterMethodCallHandler =
//    { (methodCall: FlutterMethodCall, result: FlutterResult) in
//        print("MethodChannelCallback = method: \(methodCall.method), arguments: \(methodCall.arguments)")
//        do {
//            let observableRegistration = try ObservableRegistrationRequest(methodCall)
//            switch observableRegistration.observableAction {
//            case ObservableAction.SUBSCRIBE:
//                //TODO::
//            case ObservableAction.DISPOSE:
//                let cachedDisposable = self.cachedDisposables[observableRegistration.requestId]
//                if cachedDisposable == nil {
//                    print("Could not find subscribed observable for requestId \(observableRegistration.requestId).")
//                    result(
//                        ObservableRegistrationResponse(
//                            0,
//                            nil
//                        )
//                            .toDictionary()
//                    )
//                } else {
//                    cachedDisposable.dispose()
//                    cachedDisposables.remove(observableRegistration.requestId)
//                    result(
//                        ObservableRegistrationResponse(
//                            0
//                            )
//                            .toHashMap()
//                    )
//                }
//            }
//        } catch {
//            print("Error occurred while processing methodCall. Error: \(error)")
//        }
//    }
    
    init(
        _ channelName: String,
        _ binaryMessenger: FlutterBinaryMessenger
        )
    {
        self.methodChannel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: binaryMessenger
        )
        self.methodChannel.setMethodCallHandler(
            { (methodCall: FlutterMethodCall, result: FlutterResult) in
                print("MethodChannelCallback = method: \(methodCall.method), arguments: \(methodCall.arguments)")
                do {
                    let observableRegistration = try ObservableRegistrationRequest(methodCall)
                    switch observableRegistration.observableAction {
                    case ObservableAction.SUBSCRIBE:
                        let observableSource = self.storedObservables[observableRegistration.method]
                        if (observableSource == nil) {
                            result(
                                ObservableRegistrationResponse(
                                    errorCode: PluginError.getErrorCode(PluginError.ObservableNotAvailable)(),
                                    errorMessage: "Could not find source for \(observableRegistration.method)"
                                    )
                                    .toDictionary()
                            )
                        }
                        else {
                            //Do some verification
                            if (observableRegistration.streamType != observableSource?.type)
                            {
                                result(
                                    ObservableRegistrationResponse(
                                        errorCode: PluginError.getErrorCode(PluginError.InvalidObservableType(nil))(),
                                        errorMessage: "Expected \(observableRegistration.streamType) but found \(observableSource?.type.rawValue) for method: \(observableRegistration.method)."
                                        )
                                        .toDictionary()
                                )
                            }
                            else
                            {
                                do {
                                    self.subscribeToSource(
                                        observableRegistration.requestId,
                                        observableSource!,
                                        observableRegistration.arguments
                                    )
                                    result(
                                        ObservableRegistrationResponse(
                                            errorCode: 0,
                                            errorMessage: nil
                                            )
                                            .toDictionary()
                                    )
                                } catch {
                                    result(
                                        ObservableRegistrationResponse(
                                            errorCode: PluginError.getErrorCode(PluginError.ObservableThrown)(),
                                            errorMessage: error.localizedDescription
                                            )
                                            .toDictionary()
                                    )
                                }
                            }
                        }
                    case ObservableAction.DISPOSE:
                        let cachedDisposable = self.cachedDisposables[observableRegistration.requestId]
                        if cachedDisposable == nil {
                            print("Could not find subscribed observable for requestId \(observableRegistration.requestId).")
                            result(
                                ObservableRegistrationResponse(
                                    errorCode: 0,
                                    errorMessage: nil
                                )
                                    .toDictionary()
                            )
                        } else {
                            cachedDisposable?.dispose()
                            self.cachedDisposables.removeValue(forKey: observableRegistration.requestId)
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
                    print("Error occurred while processing methodCall. Error: \(error)")
                }
            }
        )
    }
    
    private var storedObservables: [String: ObservableSourceHolder<Any>] = [:]
    
    func addObservable<T>(
        _ methodName: String,
        _ source: @escaping (T?) -> Observable<Any>,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        let sourceHolder = ObservableSourceHolder<T>(
            observable: source,
            errorHandler
        )
        storedObservables[methodName] = (sourceHolder as! ObservableSourceHolder<Any>)
    }
    
    func addSingle<T>(
        _ methodName: String,
        _ source: @escaping (T?) -> PrimitiveSequence<SingleTrait, Any>,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        let sourceHolder = ObservableSourceHolder<T>(
            single: source,
            errorHandler
        )
        storedObservables[methodName] = (sourceHolder as! ObservableSourceHolder<Any>)
    }
    
    func addCompletable<T>(
        _ methodName: String,
        _ source: @escaping (T?) -> PrimitiveSequence<CompletableTrait, Never>,
        _ errorHandler: ((Error) -> Any?)? = nil
        ) {
        let sourceHolder = ObservableSourceHolder<T>(
            completable: source,
            errorHandler
        )
        storedObservables[methodName] = (sourceHolder as! ObservableSourceHolder<Any>)
    }
    
    private var cachedDisposables: [Int: Disposable] = [:]
    private func subscribeToSource<T>(
        _ requestId: Int,
        _ source: ObservableSourceHolder<T>,
        _ arguments: T?
        )
    {
        if cachedDisposables[requestId] != nil {
            print("ERROR: A cached disposable is being overrwritten by colliding requestId.")
            cachedDisposables[requestId]?.dispose()
        }
        
        switch source.type {
        case StreamType.OBSERVABLE:
            cachedDisposables[requestId] =
                source.getSourceAsObservable(args: arguments)
                .subscribe(
                    onNext:
                    { element in
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_NEXT,
                                requestId: requestId,
                                payload: element,
                                errorMessage: nil
                            )
                        )
                    },
                    onError:
                    { error in
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_ERROR,
                                requestId: requestId,
                                payload: source.errorHandler?(error),
                                errorMessage: error.localizedDescription
                            )
                        )
                        self.cachedDisposables.removeValue(forKey: requestId)
                    },
                    onCompleted:
                    {
                        self.sendObservableCallback(
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_COMPLETE,
                                requestId: requestId,
                                payload: nil,
                                errorMessage: nil
                            )
                        )
                        self.cachedDisposables.removeValue(forKey: requestId)
                    }
                )
        case StreamType.SINGLE:
            cachedDisposables[requestId] =
                source.getSourceAsSingle(args: arguments)
                    .subscribe(
                        onSuccess:
                        { element in
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
                            self.cachedDisposables.removeValue(forKey: requestId)
                        },
                        onError:
                        { error in
                            self.sendObservableCallback(
                                ObservableCallback(
                                    callbackType: ObservableCallback.CallbackType.ON_ERROR,
                                    requestId: requestId,
                                    payload: source.errorHandler?(error),
                                    errorMessage: error.localizedDescription
                                )
                            )
                            self.cachedDisposables.removeValue(forKey: requestId)
                        }
                    )
        case StreamType.COMPLETABLE:
            cachedDisposables[requestId] =
                source.getSourceAsCompletable(args: arguments)
                    .subscribe(
                        onCompleted:
                        {
                            ObservableCallback(
                                callbackType: ObservableCallback.CallbackType.ON_COMPLETE,
                                requestId: requestId,
                                payload: nil,
                                errorMessage: nil
                            )
                            self.cachedDisposables.removeValue(forKey: requestId)
                        },
                        onError:
                        { error in
                            self.sendObservableCallback(
                                ObservableCallback(
                                    callbackType: ObservableCallback.CallbackType.ON_ERROR,
                                    requestId: requestId,
                                    payload: source.errorHandler?(error),
                                    errorMessage: error.localizedDescription
                                )
                            )
                            self.cachedDisposables.removeValue(forKey: requestId)
                        }
                    )
        }
    }
    
    private func sendObservableCallback(
        _ observableCallback: ObservableCallback
        )
    {
        DispatchQueue.main.async {
            self.methodChannel.invokeMethod(
                "callback",
                arguments: observableCallback.toDictionary()
            )
        }
    }
}
