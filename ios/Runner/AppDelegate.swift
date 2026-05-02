import UIKit
import Flutter
import flutter_local_notifications // ✅ 알림 플러그인 임포트

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        // --- [추가] 0. 알림 플러그인 초기화 및 포그라운드 설정 ---
        // 앱이 포그라운드에 있을 때도 알림이 표시되도록 대리자를 설정합니다.
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }
        
        // 알림 플러그인이 백그라운드 등에서 정상 작동하도록 콜백을 등록합니다.
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }
        
        
        // --- 1. 데이터 스트림 채널 (EventChannel) 등록 ---
        // MediaPipe의 분석 결과를 Flutter로 전송하기 위한 스트림입니다.
        let gripEventChannel = FlutterEventChannel(
            name: "com.dao.darts/grip_stream",
            binaryMessenger: controller.binaryMessenger
        )
        gripEventChannel.setStreamHandler(GripStreamBus.shared)
        
        
        // --- 2. 카메라 제어 채널 (MethodChannel) 등록 ---
        // 카메라 전환(switchCamera) 등의 명령을 처리합니다.
        let gripControlChannel = FlutterMethodChannel(
            name: "com.dao.darts/grip_control",
            binaryMessenger: controller.binaryMessenger
        )
        
        gripControlChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            if call.method == "switchCamera" {
                // ✅ [수정완료] Swift 문법에 맞게 object 파라미터만 사용합니다.
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
        // 네이티브 카메라 뷰와 Flutter 위젯을 연결합니다.
        let registrar = self.registrar(forPlugin: "kr.comong.daoapp")
        registrar?.register(
            GripCameraViewFactory(messenger: controller.binaryMessenger),
            withId: "dao_grip_camera_view"
        )

        
        // --- 4. 플러그인 등록 마무리 ---
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
