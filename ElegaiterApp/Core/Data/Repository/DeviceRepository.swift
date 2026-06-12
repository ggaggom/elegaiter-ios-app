//
//  DeviceRepository.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import Foundation
import ElegaiterSDK

/// 디바이스 저장소 인터페이스
/// 
/// Android의 `DeviceRepository` interface를 Swift protocol로 변환
/// - UserDefaults 기반 디바이스 정보 저장/로드
/// - ScannedDevice 정보 저장
public protocol DeviceRepository {
    /// 디바이스 정보 저장
    /// 
    /// Android의 `suspend fun saveDevice(device: ScannedDevice)`를 Swift로 변환
    /// - Parameter device: 저장할 디바이스 정보
    func saveDevice(_ device: ScannedDevice) async
    
    /// 저장된 디바이스 정보 로드
    /// 
    /// Android의 `suspend fun loadDevice(): ScannedDevice?`를 Swift로 변환
    /// - Returns: 저장된 디바이스 정보 (없으면 nil)
    func loadDevice() async -> ScannedDevice?
    
    /// 임계값 재설정 다이얼로그를 사용자에게 다시 보여줄지 여부를 저장합니다.
    /// ('다시 묻지 않기' 옵션 상태를 반영)
    /// 
    /// Android의 `suspend fun saveShouldShowThresholdPrompt(shouldShow: Boolean)`를 Swift로 변환
    /// - Parameter shouldShow: 다이얼로그 표시 여부 (true: 다시 보여줌, false: 다시 묻지 않음)
    func saveShouldShowThresholdPrompt(_ shouldShow: Bool) async
    
    /// 임계값 재설정 다이얼로그를 사용자에게 보여줘야 하는지 여부를 불러옵니다.
    /// 
    /// Android의 `suspend fun loadShouldShowThresholdPrompt(): Boolean`를 Swift로 변환
    /// - Returns: 다이얼로그 표시 여부 (기본값: true, 즉 기본적으로는 보여줌)
    func loadShouldShowThresholdPrompt() async -> Bool
}

/// 디바이스 저장소 구현체
/// 
/// Android의 `DeviceRepositoryImpl`을 Swift로 변환
/// - UserDefaults를 사용하여 디바이스 정보 저장
/// - SharedPreferences의 `device_prefs`를 UserDefaults로 변환
public final class DeviceRepositoryImpl: DeviceRepository {
    
    // MARK: - Properties
    
    /// UserDefaults 인스턴스
    /// 
    /// Android의 `SharedPreferences("device_prefs", ...)`에 해당
    private let userDefaults: UserDefaults
    
    /// UserDefaults 키
    private enum Keys {
        static let deviceName = "device_name"
        static let deviceAddress = "device_address"
        static let shouldShowThresholdPrompt = "should_show_threshold_prompt"
    }
    
    // MARK: - Initialization
    
    /// 초기화
    /// 
    /// - Parameter userDefaults: UserDefaults 인스턴스 (nil이면 standard 사용)
    public init(userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults ?? UserDefaults.standard
    }
    
    // MARK: - DeviceRepository
    
    public func saveDevice(_ device: ScannedDevice) async {
        userDefaults.set(device.name, forKey: Keys.deviceName)
        userDefaults.set(device.address, forKey: Keys.deviceAddress)
    }
    
    public func loadDevice() async -> ScannedDevice? {
        guard let name = userDefaults.string(forKey: Keys.deviceName),
              let address = userDefaults.string(forKey: Keys.deviceAddress) else {
            return nil
        }
        
        return ScannedDevice(name: name, address: address)
    }
    
    public func saveShouldShowThresholdPrompt(_ shouldShow: Bool) async {
        userDefaults.set(shouldShow, forKey: Keys.shouldShowThresholdPrompt)
    }
    
    public func loadShouldShowThresholdPrompt() async -> Bool {
        // UserDefaults에서 값을 가져오고, 없으면 기본값 true 반환
        if userDefaults.object(forKey: Keys.shouldShowThresholdPrompt) == nil {
            return true // 기본값: true (보여줌)
        }
        return userDefaults.bool(forKey: Keys.shouldShowThresholdPrompt)
    }
}

