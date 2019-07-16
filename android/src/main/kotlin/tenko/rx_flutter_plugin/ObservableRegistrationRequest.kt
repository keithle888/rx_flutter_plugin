package tenko.rx_flutter_plugin

import io.flutter.plugin.common.MethodCall

data class ObservableRegistrationRequest (
        val method: String,
        val streamType: StreamType,
        val requestId: Int,
        val arguments: Any?,
        val observableAction: ObservableAction
) {
    companion object {
        fun constructFromMethodCall(methodCall: MethodCall): ObservableRegistrationRequest {
            return ObservableRegistrationRequest(
                    methodCall.method,
                    StreamType.valueOf(methodCall.argumentNotNull(Field.STREAM_TYPE)),
                    methodCall.argumentNotNull(Field.REQUEST_ID),
                    methodCall.argument(Field.PAYLOAD),
                    ObservableAction.valueOf(methodCall.argumentNotNull(Field.OBSERVABLE_ACTION))
            )
        }
    }
}

data class ObservableRegistrationResponse (
        val errorCode: Int,
        val errorMessage: String? = null
) {
    fun toHashMap(): HashMap<String, Any> {
        val hashMap = HashMap<String, Any>()
        hashMap[Field.ERROR_CODE] = errorCode
        if (errorMessage != null) {
            hashMap[Field.ERROR_MESSAGE] = errorMessage
        }
        return hashMap
    }
}