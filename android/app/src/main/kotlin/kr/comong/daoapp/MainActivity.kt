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

        // 1) EventChannel (데이터 송신용)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    GripStreamBus.eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    GripStreamBus.eventSink = null
                }
            })

        // 2) PlatformView 등록 (Factory에 messenger 전달 추가!)
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "dao_grip_camera_view",
                GripCameraViewFactory(flutterEngine.dartExecutor.binaryMessenger, this)
            )
    }
}