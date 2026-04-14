import Foundation
import Flutter
import UIKit
import AVFoundation
import MediaPipeTasksVision

class GripCameraPlatformView: NSObject, FlutterPlatformView, AVCaptureVideoDataOutputSampleBufferDelegate, HandLandmarkerLiveStreamDelegate {
    private var _containerView: UIView
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let videoOutput = AVCaptureVideoDataOutput()
    private let cameraQueue = DispatchQueue(label: "com.dao.grip.camera.queue")
    private var handLandmarker: HandLandmarker?
    
    private var isStopped = false

    init(frame: CGRect, messenger: FlutterBinaryMessenger) {
        self._containerView = UIView(frame: frame)
        super.init()
        
        // 🚀 [초기화] 새 화면 진입 시 이전 데이터 잔상 제거
        let clearPayload: [String: Any] = [
            "w": 720,
            "h": 1280,
            "landmarks": []
        ]
        GripStreamBus.send(clearPayload)

        setupMediaPipe()
        setupCamera()
        
        NotificationCenter.default.addObserver(self, selector: #selector(toggleCamera), name: Notification.Name("SwitchCamera"), object: nil)
    }

    func view() -> UIView { return _containerView }

    private func setupMediaPipe() {
        guard let modelPath = Bundle.main.path(forResource: "hand_landmarker", ofType: "task") else {
            print("❌ Error: hand_landmarker.task 파일을 찾을 수 없습니다.")
            return
        }
        
        let options = HandLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .liveStream
        options.numHands = 1
        options.minHandDetectionConfidence = 0.5
        options.minHandPresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        options.handLandmarkerLiveStreamDelegate = self
        
        do {
            handLandmarker = try HandLandmarker(options: options)
            print("✅ MediaPipe Hand Landmarker 초기화 성공")
        } catch {
            print("❌ MediaPipe 초기화 실패: \(error)")
        }
    }

    private func setupCamera() {
        cameraQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 🚀 [안정화] 이전 세션이 혹시 남아있다면 정리 후 시작
            if self.session.isRunning { self.session.stopRunning() }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .hd1280x720

            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                self.session.commitConfiguration()
                return
            }

            if self.session.canAddInput(videoInput) { self.session.addInput(videoInput) }
            
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(self, queue: self.cameraQueue)
            
            if self.session.canAddOutput(self.videoOutput) { self.session.addOutput(self.videoOutput) }
            
            self.updateVideoOrientation()
            self.session.commitConfiguration()
            self.session.startRunning()

            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
                self.previewLayer?.videoGravity = .resizeAspectFill
                self.previewLayer?.frame = self._containerView.bounds
                if let layer = self.previewLayer {
                    self._containerView.layer.addSublayer(layer)
                }
            }
        }
    }

    @objc private func toggleCamera() {
        cameraQueue.async { [weak self] in
            guard let self = self, !self.isStopped else { return }
            self.session.beginConfiguration()
            if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
                self.session.removeInput(currentInput)
                let newPosition: AVCaptureDevice.Position = (currentInput.device.position == .front) ? .back : .front
                if let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                   let newInput = try? AVCaptureDeviceInput(device: newDevice) {
                    if self.session.canAddInput(newInput) { self.session.addInput(newInput) }
                }
            }
            self.updateVideoOrientation()
            self.session.commitConfiguration()
        }
    }

    private func updateVideoOrientation() {
        if let connection = self.videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            if let input = self.session.inputs.first as? AVCaptureDeviceInput {
                connection.isVideoMirrored = (input.device.position == .front)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isStopped, let landmarker = handLandmarker else { return }
        let timestampMs = Int(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)) * 1000)
        guard let image = try? MPImage(sampleBuffer: sampleBuffer, orientation: .up) else { return }
        try? landmarker.detectAsync(image: image, timestampInMilliseconds: timestampMs)
    }

    func handLandmarker(_ handLandmarker: HandLandmarker, didFinishDetection result: HandLandmarkerResult?, timestampInMilliseconds: Int, error: Error?) {
        guard !isStopped, let result = result, !result.landmarks.isEmpty else { return }
        let hand = result.landmarks[0]
        let raw = hand.flatMap { [Double($0.x), Double($0.y), Double($0.z)] }
        let payload: [String: Any] = ["w": 720, "h": 1280, "landmarks": raw]
        GripStreamBus.send(payload)
    }

    // 🚀 [중요 수정] 리소스 해제 로직 강화
    func dispose() {
        isStopped = true
        NotificationCenter.default.removeObserver(self)
        
        cameraQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 1. 세션 즉시 중지
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            // 2. 모든 입출력 강제 제거 (세션 꼬임 방지 핵심)
            self.session.beginConfiguration()
            for input in self.session.inputs { self.session.removeInput(input) }
            for output in self.session.outputs { self.session.removeOutput(output) }
            self.session.commitConfiguration()
            
            // 3. 분석 모델 및 레이어 제거
            self.handLandmarker = nil
            
            DispatchQueue.main.async {
                self.previewLayer?.removeFromSuperlayer()
                self.previewLayer = nil
            }
            print("✅ iOS Camera Session Safely Cleared for Re-capture")
        }
    }
}

class GripCameraViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    init(messenger: FlutterBinaryMessenger) { self.messenger = messenger }
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return GripCameraPlatformView(frame: frame, messenger: messenger)
    }
}
