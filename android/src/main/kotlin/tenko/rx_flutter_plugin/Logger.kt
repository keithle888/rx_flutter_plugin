package tenko.rx_flutter_plugin

import android.util.Log

object Logger {
    private val TAG = "rx_flutter_plugin"
    var debug = false

    fun d(msg: String) {
        if (debug) print(Log.DEBUG, msg)
    }

    fun d(t: Throwable? = null, msg: String) {
        if (debug) print(Log.DEBUG, msg, t)
    }

    fun v(msg: String) {
        if (debug) print(Log.VERBOSE, msg)
    }

    fun v(t: Throwable? = null, msg: String) {
        if (debug) print(Log.VERBOSE, msg, t)
    }

    fun e(msg: String) {
        if (debug) print(Log.ERROR, msg)
    }

    fun e(t: Throwable? = null, msg: String) {
        if (debug) print(Log.ERROR, msg, t)
    }

    fun w(msg: String) {
        if (debug) print(Log.WARN, msg)
    }

    fun w(t: Throwable? = null, msg: String) {
        if (debug) print(Log.WARN, msg, t)
    }

    fun i(msg: String) {
        if (debug) print(Log.DEBUG, msg)
    }

    fun i(t: Throwable? = null, msg: String) {
        if (debug) print(Log.DEBUG, msg, t)
    }

    private fun print(level: Int, msg: String, throwable: Throwable? = null) {
        if (throwable == null) {
            when (level) {
                Log.DEBUG -> Log.d(TAG, msg)
                Log.ERROR -> Log.e(TAG, msg)
                Log.INFO -> Log.i(TAG, msg)
                Log.WARN -> Log.w(TAG, msg)
                Log.VERBOSE -> Log.v(TAG, msg)
            }
        } else {
            when (level) {
                Log.DEBUG -> Log.d(TAG, msg, throwable)
                Log.ERROR -> Log.e(TAG, msg, throwable)
                Log.INFO -> Log.i(TAG, msg, throwable)
                Log.WARN -> Log.w(TAG, msg, throwable)
                Log.VERBOSE -> Log.v(TAG, msg, throwable)
            }
        }
    }
}