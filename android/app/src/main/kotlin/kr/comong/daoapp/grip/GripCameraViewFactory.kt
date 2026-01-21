package kr.comong.daoapp.grip

import android.app.Activity
import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class GripCameraViewFactory(
    private val activity: Activity, // appContext는 이제 필요 없음
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    // ⚠️ 중요: 여기서 넘어오는 context가 Flutter와 연결된 진짜 context입니다.
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        // 반드시 nullable 체크 후 context!! 또는 context를 넘겨야 함
        return GripCameraPlatformView(context!!, activity)
    }
}