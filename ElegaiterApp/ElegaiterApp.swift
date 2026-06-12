//
//  ElegaiterApp.swift
//  ElegaiterApp
//
//  Created by yiwoosolution on 11/24/25.
//

import SwiftUI
import UIKit

@main
struct ElegaiterApp: App {
    init() {
        // 폰트 이름 확인 (디버그 모드에서만)
        #if DEBUG
        printAvailableFonts()
        #endif
        
        // 언어 설정 초기화: 앱 시작 시 저장된 언어 또는 시스템 언어로 Bundle 설정
        Bundle.setLanguage(LanguageManager.shared.currentLanguage)
        
        // SDK 초기화 최적화: 앱 시작 시 백그라운드에서 SDK를 미리 초기화
        // 이렇게 하면 SplashView가 표시되기 전에 SDK 초기화가 완료되어
        // 로그인 상태 확인 시 지연이 없습니다.
        SDKManager.shared.preload()
    }
    
    var body: some Scene {
        WindowGroup {
            SdkInitGateView {
                AppNavigation()
            }
        }
    }
    
    /// 사용 가능한 폰트 목록 출력 (Pretendard 폰트 확인용)
    private func printAvailableFonts() {
        print("=== 사용 가능한 폰트 목록 ===")
        for family in UIFont.familyNames.sorted() {
            if family.contains("Pretendard") || family.contains("pretendard") {
                print("\n📌 Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("   Font: \(name)")
                }
            }
        }
        print("===========================")
    }
}

