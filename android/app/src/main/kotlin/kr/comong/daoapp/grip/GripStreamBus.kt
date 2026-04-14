package kr.comong.daoapp.grip

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

object GripStreamBus {

    var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    /**
     * Flutter EventChannel로 payload 전송
     * - Map<String, Any> / List<Double> 등
     * - StandardMessageCodec 지원 타입만 사용
     */
    fun send(payload: Any) {
        val sink = eventSink ?: return
        mainHandler.post {
            sink.success(payload)
        }
    }

    // (호환용 / 디버그용)
    fun sendLandmarks(raw: ArrayList<Double>) {
        send(raw)
    }
}
