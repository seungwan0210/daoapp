package kr.comong.daoapp

import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

import kr.comong.daoapp.grip.GripCameraViewFactory
import kr.comong.daoapp.grip.GripStreamBus

class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME = "com.dao.darts/grip_stream"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1) EventChannel: Flutter가 listen하면 sink를 저장해둠
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d("DAO_GRIP", "EventChannel onListen")
                    GripStreamBus.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    Log.d("DAO_GRIP", "EventChannel onCancel")
                    GripStreamBus.eventSink = null
                }
            })

        // 2) PlatformView 등록
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "dao_grip_camera_view",
                // ✅ Factory 생성자 수정에 맞춰서 'this(activity)'만 넘김
                GripCameraViewFactory(this)
            )
    }
}
