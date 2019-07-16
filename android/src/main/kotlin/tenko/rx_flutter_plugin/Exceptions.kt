package tenko.rx_flutter_plugin

import kotlin.Exception

sealed class PluginException(val errorCode: Int, cause: String?): Exception(cause) {
    class InvalidObservableType(cause: String? = null): PluginException(1, cause)
    class ObservableState(cause: String? = null): PluginException(2, cause)
    class ObservableNotAvailable(cause: String? = null): PluginException(3, cause)
    class ObservableThrown(cause: String? = null): PluginException(4, cause)
}