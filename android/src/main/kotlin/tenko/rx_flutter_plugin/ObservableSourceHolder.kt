package tenko.rx_flutter_plugin

import io.reactivex.CompletableSource
import io.reactivex.ObservableSource
import io.reactivex.SingleSource

class ObservableSourceHolder<T> {
    internal lateinit var type: StreamType
    internal lateinit var sourceGenerator: (args: T?) -> Any
    internal var errorHandler: ((Throwable) -> Any?)? = null

    //Not in use atm.
//    class Builder<T> {
//        val holder = ObservableSourceHolder<T>()
//
//        fun build(): ObservableSourceHolder<T> {
//            return holder
//        }
//    }

    companion object {
        fun <T> observableHolder(observable: (arguments: T?) -> ObservableSource<*>, errorHandler: ((Throwable) -> Any?)? = null): ObservableSourceHolder<T> {
            val holder =  ObservableSourceHolder<T>()
            holder.type = StreamType.observable
            holder.sourceGenerator = observable
            holder.errorHandler = errorHandler
            return holder
        }

        fun <T> singleHolder(observable: (arguments: T?) -> SingleSource<*>, errorHandler: ((Throwable) -> Any?)? = null): ObservableSourceHolder<T> {
            val holder =  ObservableSourceHolder<T>()
            holder.type = StreamType.single
            holder.sourceGenerator = observable
            holder.errorHandler = errorHandler
            return holder
        }

        fun <T> completableHolder(observable: (arguments: T?) -> CompletableSource, errorHandler: ((Throwable) -> Any?)? = null): ObservableSourceHolder<T> {
            val holder =  ObservableSourceHolder<T>()
            holder.type = StreamType.completable
            holder.sourceGenerator = observable
            holder.errorHandler = errorHandler
            return holder
        }
    }

    fun getSourceAsObservable(args: T?): ObservableSource<*> {
        return sourceGenerator(args) as ObservableSource<*>
    }

    fun getSourceAsSingle(args: T?): SingleSource<*> {
        return sourceGenerator(args) as SingleSource<*>
    }

    fun getSourceAsCompletable(args: T?): CompletableSource {
        return sourceGenerator(args) as CompletableSource
    }
}