package kr.comong.daoapp.grip

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.BinaryMessenger // 추가됨
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class GripCameraViewFactory(
    private val messenger: BinaryMessenger, // ✅ 추가됨
    private val activity: Activity,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        // View 생성 시 messenger도 같이 넘김
        return GripCameraPlatformView(context!!, activity, messenger, viewId)
    }
}