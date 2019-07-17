package tenko.rx_flutter_plugin

import io.flutter.plugin.common.MethodCall

inline fun <reified T> MethodCall.argumentNotNull(key: String): T {
    return this.argument<T>(key) ?: throw Exception("$key is null.")
}