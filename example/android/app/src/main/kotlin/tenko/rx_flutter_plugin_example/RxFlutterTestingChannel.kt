package tenko.rx_flutter_plugin_example

import io.flutter.plugin.common.BinaryMessenger
import io.reactivex.Completable
import io.reactivex.Observable
import io.reactivex.Single
import tenko.rx_flutter_plugin.RxFlutterMethodChannel

/**
 * Used for functional testing.
 */
class RxFlutterTestingChannel(binaryMessenger: BinaryMessenger) {
    val channel = RxFlutterMethodChannel("rx_flutter_plugin", binaryMessenger)

    init {
        channel.addCompletable<Void>("testCompletable_success", {Completable.complete()})

        channel.addCompletable<Void>("testCompletable_withError", {Completable.error(Exception("Test Error"))})

        channel.addSingle<Void>("testSingle_returns1", {Single.just(1)})

        channel.addObservable<Void>("testObservable_returnsIncreasingInts_success", {Observable.fromIterable(listOf(1,2,3,4,6,7))})
    }
}