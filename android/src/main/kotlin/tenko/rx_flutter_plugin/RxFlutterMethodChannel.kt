package tenko.rx_flutter_plugin

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.reactivex.*
import io.reactivex.disposables.Disposable

class RxFlutterMethodChannel(val channelName: String, binaryMessenger: BinaryMessenger) {
    private val methodChannel = MethodChannel(binaryMessenger, channelName)

    private val methodChannelCallback: (MethodCall, MethodChannel.Result) -> Unit = { methodCall, result ->
        Logger.d("MethodChannelCallback = channel: $channelName, method: ${methodCall.method}, args: ${methodCall.arguments}")
        val observableRegistration = ObservableRegistrationRequest.constructFromMethodCall(methodCall)
        when (observableRegistration.observableAction) {
            ObservableAction.subscribe -> {
                val observableSource = storedObservables[observableRegistration.method]
                if (observableSource == null) {
                    result.success(
                            ObservableRegistrationResponse(
                                    PluginException.ObservableNotAvailable().errorCode,
                                    "Could not find source for ${observableRegistration.method}"
                            )
                                    .toHashMap()
                    )
                }
                else {
                    //Do some verification
                    when {
                        observableRegistration.streamType != observableSource.type -> {
                            result.success(
                                    ObservableRegistrationResponse(
                                            PluginException.InvalidObservableType().errorCode,
                                            "Expected ${observableRegistration.streamType} but found ${observableSource.type} for method: ${observableRegistration.method}."
                                    )
                                            .toHashMap()
                            )

                        }

                        else -> {
                            try {
                                subscribeToSource(
                                        observableRegistration.requestId,
                                        observableSource,
                                        methodCall.argument(Field.PAYLOAD)
                                )
                                result.success(
                                        ObservableRegistrationResponse(
                                                0
                                        )
                                                .toHashMap()
                                )
                            } catch (e: Exception) {
                                result.success(
                                        ObservableRegistrationResponse(
                                                PluginException.ObservableThrown().errorCode,
                                                e.localizedMessage
                                        )
                                                .toHashMap()
                                )
                            }
                        }
                    }
                }
            }

            ObservableAction.dispose -> {
                val cachedDisposable = cachedDisposables[observableRegistration.requestId]
                if (cachedDisposable == null) {
                    Logger.w("Could not find subscribed observable for requestId ${observableRegistration.requestId}.")
                    result.success(
                            ObservableRegistrationResponse(
                                    0
                            )
                                    .toHashMap()
                    )
                } else {
                    cachedDisposable.dispose()
                    cachedDisposables.remove(observableRegistration.requestId)
                    result.success(
                            ObservableRegistrationResponse(
                                    0
                            )
                                    .toHashMap()
                    )
                }
            }
        }
    }

    init {
        methodChannel.setMethodCallHandler(methodChannelCallback)
    }

    /**
     * Used to hold the mappings of methods to the observable source.
     */
    private val storedObservables = HashMap<String, ObservableSourceHolder<*>>()

    fun <T> addObservable(
            methodName: String,
            source: (arguments: T?) -> ObservableSource<Any>,
            errorHandler: ((Throwable) -> Any?)? = null
    ) {
        Logger.d("Observable source registered. methodName: $methodName")
        storedObservables[methodName] = ObservableSourceHolder.observableHolder(source, errorHandler)
    }

    fun <T> addSingle(
            methodName: String,
            source: (arguments: T?) -> SingleSource<Any>,
            errorHandler: ((Throwable) -> Any?)? = null
    ) {
        Logger.d("Single source registered. methodName: $methodName")
        storedObservables[methodName] = ObservableSourceHolder.singleHolder(source, errorHandler)
    }

    fun <T> addCompletable(
            methodName: String,
            source: (arguments: T?) -> CompletableSource,
            errorHandler: ((Throwable) -> Any?)? = null
    ) {
        Logger.d("Completable source registered. methodName: $methodName")
        storedObservables[methodName] = ObservableSourceHolder.completableHolder(source, errorHandler)
    }

    private val mainThreadHandler = Handler(Looper.getMainLooper())
    private fun sendObservableCallback(observableCallback: ObservableCallback) {
        Logger.d("sendObservableCallback(): $observableCallback")
        //Use arbitrary method for now, method is not used.
        //No need to include callback. It bears no useful information
        //Ensure all calls are done on UI thread
        mainThreadHandler.post{
            methodChannel.invokeMethod(
                    "callback",
                    mapOf(
                            Field.OBSERVABLE_CALLBACK to observableCallback.observableCallbackType.name,
                            Field.PAYLOAD to observableCallback.payload,
                            Field.REQUEST_ID to observableCallback.requestId,
                            Field.ERROR_MESSAGE to observableCallback.errorMessage
                    )
            )
        }
    }


    private val cachedDisposables = HashMap<Int, Disposable>()
    private fun <T> subscribeToSource(requestId: Int, source: ObservableSourceHolder<T>, arguments: T?) {
        cachedDisposables[requestId] =
                when (source.type) {
                    StreamType.observable -> {
                        Observable.defer {
                            source.getSourceAsObservable(arguments)
                        }.subscribe({
                            Logger.d("onNext() = requestId: $requestId, payload: $it")
                            sendObservableCallback(
                                    ObservableCallback(
                                            ObservableCallbackType.onNext,
                                            requestId,
                                            it,
                                            null
                                    )
                            )
                        }, {
                            Logger.w(it, "onError() = requestId: $requestId")

                            val payload =
                                    when {
                                        source.errorHandler != null -> source.errorHandler?.invoke(it)
                                        defaultExceptionHandler != null -> defaultExceptionHandler?.handleException(it)
                                        else -> null
                                    }

                            sendObservableCallback(
                                    ObservableCallback(
                                            ObservableCallbackType.onError,
                                            requestId,
                                            payload,
                                            it.localizedMessage
                                    )
                            )
                            cachedDisposables.remove(requestId)
                        }, {
                            Logger.d("onComplete() = requestId: $requestId")
                            sendObservableCallback(
                                    ObservableCallback(
                                            ObservableCallbackType.onComplete,
                                            requestId,
                                            null,
                                            null
                                    )
                            )
                            cachedDisposables.remove(requestId)
                        })
                    }

                    StreamType.single -> {
                        Single.defer {
                            source.getSourceAsSingle(arguments)
                        }.subscribe({
                            Logger.d("onSuccess() = requestId: $requestId, payload: $it")
                            sendObservableCallback(
                                    ObservableCallback(
                                            ObservableCallbackType.onNext,
                                            requestId,
                                            it,
                                            null
                                    )
                            )
                            sendObservableCallback(
                                    ObservableCallback(
                                            ObservableCallbackType.onComplete,
                                            requestId,
                                            null,
                                            null
                                    )
                            )
                            cachedDisposables.remove(requestId)
                        }, {
                            Logger.w(it, "onError() = requestId: $requestId")

                            val payload =
                                    when {
                                        source.errorHandler != null -> source.errorHandler?.invoke(it)
                                        defaultExceptionHandler != null -> defaultExceptionHandler?.handleException(it)
                                        else -> null
                                    }

                            sendObservableCallback(
                                    ObservableCallback(
                                            ObservableCallbackType.onError,
                                            requestId,
                                            payload,
                                            it.localizedMessage
                                    )
                            )
                            cachedDisposables.remove(requestId)
                        })
                    }

                    StreamType.completable -> {
                        Completable.defer {
                            source.getSourceAsCompletable(arguments)
                        }.subscribe({
                            Logger.d("onComplete() = requestId: $requestId")
                            sendObservableCallback(
                                    ObservableCallback(
                                            ObservableCallbackType.onComplete,
                                            requestId,
                                            null,
                                            null
                                    )
                            )
                            cachedDisposables.remove(requestId)
                        }, {
                            Logger.w(it, "onError() = requestId: $requestId")

                            val payload =
                                    when {
                                        source.errorHandler != null -> source.errorHandler?.invoke(it)
                                        defaultExceptionHandler != null -> defaultExceptionHandler?.handleException(it)
                                        else -> null
                                    }

                            sendObservableCallback(
                                    ObservableCallback(
                                            ObservableCallbackType.onError,
                                            requestId,
                                            payload,
                                            it.localizedMessage
                                    )
                            )
                            cachedDisposables.remove(requestId)
                        })
                    }
                }
    }

    private var defaultExceptionHandler: ExceptionHandler? = null

    /**
     * Set the default ExceptionHandler to be used when an Rx subscription throws.
     * If null is returned by the given ExceptionHandler, the default behaviour is used (ObservableThrownException).
     */
    fun setDefaultExceptionHandler(exceptionHandler: ExceptionHandler) {
        defaultExceptionHandler = exceptionHandler
    }
}