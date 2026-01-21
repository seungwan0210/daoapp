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
    private val activity: Activity
) : PlatformView {

    private val previewView: PreviewView = PreviewView(context).apply {
        layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        )

        // ✅ 카메라 화면은 항상 꽉 채움 (Flutter 오버레이와 동일 조건)
        scaleType = PreviewView.ScaleType.FILL_CENTER

        // ✅ TextureView 기반 (SurfaceView 겹침/검정 방지)
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE

        setBackgroundColor(android.graphics.Color.TRANSPARENT)

        addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                bindCameraSafely()
            }
            override fun onViewDetachedFromWindow(v: View) {
                unbindCamera()
            }
        })
    }

    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var cameraProvider: ProcessCameraProvider? = null
    private var handLandmarker: HandLandmarker? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var preview: Preview? = null

    // ✅ 회전 반영 후 실제 분석 프레임 크기
    private var lastFrameW: Int = 0
    private var lastFrameH: Int = 0

    init {
        setupMediaPipe()
    }

    override fun getView(): View = previewView

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
                sendResult(result)
            }
            .build()

        try {
            handLandmarker = HandLandmarker.createFromOptions(context, options)
        } catch (e: Exception) {
            Log.e("DAO_GRIP", "MediaPipe init failed", e)
        }
    }

    private fun bindCameraSafely() {
        val providerFuture = ProcessCameraProvider.getInstance(context)
        providerFuture.addListener({
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

                val selector = CameraSelector.DEFAULT_BACK_CAMERA
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
                landmarker.detectAsync(mpImage, ts)

            } catch (e: Exception) {
                Log.e("DAO_GRIP", "Analyze error", e)
            }
        }

        imageProxy.close()
    }

    private fun sendResult(result: HandLandmarkerResult) {
        if (result.landmarks().isEmpty()) return

        val hand = result.landmarks()[0]
        val raw = ArrayList<Double>(63)

        for (lm in hand) {
            raw.add(lm.x().toDouble())
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

    override fun dispose() {
        unbindCamera()
        try { handLandmarker?.close() } catch (_: Exception) {}
        try { cameraExecutor.shutdown() } catch (_: Exception) {}
    }
}
