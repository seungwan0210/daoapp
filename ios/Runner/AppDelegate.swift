import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // --- 1. 데이터 스트림 채널 (EventChannel) 등록 ---
        // MediaPipe 분석 결과를 Flutter로 실시간 전송합니다.
        let gripEventChannel = FlutterEventChannel(
            name: "com.dao.darts/grip_stream",
            binaryMessenger: controller.binaryMessenger
        )
        gripEventChannel.setStreamHandler(GripStreamBus.shared)
        
        
        // --- 2. 카메라 제어 채널 (MethodChannel) 등록 ---
        // Flutter에서 보낸 'switchCamera' 같은 명령을 처리합니다.
        let gripControlChannel = FlutterMethodChannel(
            name: "com.dao.darts/grip_control",
            binaryMessenger: controller.binaryMessenger
        )
        
        gripControlChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            if call.method == "switchCamera" {
                // ✅ NotificationCenter를 통해 현재 활성화된 카메라 뷰에 전환 신호를 보냅니다.
                NotificationCenter.default.post(
                    name: Notification.Name("SwitchCamera"),
                    object: nil
                )
                result(true)
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        
        // --- 3. 카메라 플랫폼 뷰(UiKitView) 등록 ---
        // Flutter의 DaoGripCameraView 위젯과 네이티브 뷰를 연결합니다.
        let registrar = self.registrar(forPlugin: "kr.comong.daoapp")
        registrar?.register(
            GripCameraViewFactory(messenger: controller.binaryMessenger),
            withId: "dao_grip_camera_view"
        )

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
