package kr.comong.daoapp.grip

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult

class GripCameraPlatformView(
    private val context: Context,
    private val activity: Activity,
    messenger: BinaryMessenger,
    viewId: Int
) : PlatformView, MethodChannel.MethodCallHandler {

    private val methodChannel = MethodChannel(messenger, "com.dao.darts/grip_control")

    // ✅ [안전장치 1] 종료 플래그 (Volatile로 스레드 간 즉시 동기화)
    @Volatile
    private var isShutdown = false

    private val previewView: PreviewView = PreviewView(context).apply {
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )
        scaleType = PreviewView.ScaleType.FILL_CENTER
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
        setBackgroundColor(android.graphics.Color.TRANSPARENT)

        addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                if (!isShutdown) bindCameraSafely()
            }
            override fun onViewDetachedFromWindow(v: View) {
                // 여기서 unbind하면 화면 전환 시 깜빡일 수 있으므로 dispose에서 처리
            }
        })
    }

    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var cameraProvider: ProcessCameraProvider? = null
    private var handLandmarker: HandLandmarker? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var preview: Preview? = null

    private var isFrontCamera = false
    private var lastFrameW: Int = 0
    private var lastFrameH: Int = 0

    init {
        setupMediaPipe()
        methodChannel.setMethodCallHandler(this)
    }

    override fun getView(): View = previewView

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (isShutdown) return // 종료 중이면 무시

        if (call.method == "switchCamera") {
            toggleCamera()
            result.success(null)
        } else {
            result.notImplemented()
        }
    }

    private fun toggleCamera() {
        if (isShutdown) return
        isFrontCamera = !isFrontCamera
        unbindCamera()
        bindCameraSafely()
    }

    private fun setupMediaPipe() {
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("hand_landmarker.task")
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.LIVE_STREAM)
            .setNumHands(1)
            .setMinHandDetectionConfidence(0.5f)
            .setMinHandPresenceConfidence(0.5f)
            .setMinTrackingConfidence(0.5f)
            .setResultListener { result: HandLandmarkerResult, _ ->
                // ✅ [안전장치 2] 결과 전송 전 종료 여부 체크
                if (!isShutdown) {
                    sendResult(result)
                }
            }
            .build()

        try {
            handLandmarker = HandLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            Log.e("DAO_GRIP", "MediaPipe init failed", e)
        }
    }

    private fun bindCameraSafely() {
        if (isShutdown) return

        val providerFuture = ProcessCameraProvider.getInstance(context)
        providerFuture.addListener({
            if (isShutdown) return@addListener // 비동기 실행 시점에도 체크

            try {
                cameraProvider = providerFuture.get()
                cameraProvider?.unbindAll()

                preview = Preview.Builder()
                    .setTargetAspectRatio(AspectRatio.RATIO_16_9)
                    .build()
                    .also { it.setSurfaceProvider(previewView.surfaceProvider) }

                imageAnalysis = ImageAnalysis.Builder()
                    .setTargetAspectRatio(AspectRatio.RATIO_16_9)
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                    .build()
                    .also { analysis ->
                        analysis.setAnalyzer(cameraExecutor) { imageProxy ->
                            analyzeFrame(imageProxy)
                        }
                    }

                val selector = if (isFrontCamera) {
                    CameraSelector.DEFAULT_FRONT_CAMERA
                } else {
                    CameraSelector.DEFAULT_BACK_CAMERA
                }

                val owner = activity as LifecycleOwner
                cameraProvider?.bindToLifecycle(owner, selector, preview, imageAnalysis)

            } catch (e: Exception) {
                Log.e("DAO_GRIP", "Camera bind failed", e)
            }
        }, ContextCompat.getMainExecutor(context))
    }

    private fun unbindCamera() {
        try { cameraProvider?.unbindAll() } catch (_: Exception) {}
    }

    private fun analyzeFrame(imageProxy: ImageProxy) {
        // ✅ [안전장치 3] 분석 시작 전 종료 여부 체크 (가장 중요!)
        // 뷰가 사라졌는데(isShutdown=true) 이미지가 들어오면 즉시 닫고 리턴
        if (isShutdown) {
            imageProxy.close()
            return
        }

        val landmarker = handLandmarker ?: run {
            imageProxy.close()
            return
        }

        val bitmap = imageProxy.toRgbaBitmap()
        val ts = System.currentTimeMillis()

        if (bitmap != null) {
            try {
                val rotation = imageProxy.imageInfo.rotationDegrees.toFloat()
                val matrix = Matrix().apply { postRotate(rotation) }

                val rotatedBitmap = Bitmap.createBitmap(
                    bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true
                )

                lastFrameW = rotatedBitmap.width
                lastFrameH = rotatedBitmap.height

                val mpImage: MPImage = BitmapImageBuilder(rotatedBitmap).build()

                // 다시 한번 체크
                if (!isShutdown) {
                    landmarker.detectAsync(mpImage, ts)
                }

            } catch (e: Exception) {
                Log.e("DAO_GRIP", "Analyze error", e)
            }
        }
        imageProxy.close()
    }

    private fun sendResult(result: HandLandmarkerResult) {
        if (isShutdown) return // 전송 차단
        if (result.landmarks().isEmpty()) return

        val hand = result.landmarks()[0]
        val raw = ArrayList<Double>(63)

        for (lm in hand) {
            var x = lm.x().toDouble()
            if (isFrontCamera) {
                x = 1.0 - x
            }
            raw.add(x)
            raw.add(lm.y().toDouble())
            raw.add(lm.z().toDouble())
        }

        val payload = hashMapOf<String, Any>(
            "w" to lastFrameW,
            "h" to lastFrameH,
            "landmarks" to raw
        )

        GripStreamBus.send(payload)
    }

    // 🔥 [핵심] 뷰가 파괴될 때 호출됨
    override fun dispose() {
        isShutdown = true // 1. 모든 작업 정지 신호

        methodChannel.setMethodCallHandler(null)
        unbindCamera() // 2. 카메라 연결 해제

        // 3. MediaPipe 종료 (try-catch 필수)
        try { handLandmarker?.close() } catch (_: Exception) {}
        handLandmarker = null

        // 4. 스레드 종료
        try { cameraExecutor.shutdownNow() } catch (_: Exception) {}
    }
}