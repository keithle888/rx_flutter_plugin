package tenko.rx_flutter_plugin

enum class ObservableCallbackType {
    onNext, onComplete, onError
}

data class ObservableCallback(
        val observableCallbackType: ObservableCallbackType,
        val requestId: Int,
        val payload: Any?,
        val errorMessage: String?
) {

}