//
//  NetworkMonitorImpl.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import Foundation
import Combine
import Network
import ElegaiterSDK

/// iOS 네트워크 모니터 구현체
/// 
/// Android의 `ConnectivityManagerNetworkMonitor`를 iOS로 변환
/// - `NWPathMonitor`를 사용한 실시간 네트워크 상태 감지
/// - Combine Publisher로 상태 스트리밍
final class NetworkMonitorImpl: NetworkMonitor {
    /// 네트워크 경로 모니터
    private let pathMonitor = NWPathMonitor()
    /// 모니터 큐
    private let monitorQueue = DispatchQueue(label: "com.elegaiter.network.monitor")
    
    /// 네트워크 온라인 상태 Publisher
    /// 
    /// Android의 `Flow<Boolean>`을 Combine `Publisher`로 변환
    /// - true: 네트워크 연결됨
    /// - false: 네트워크 연결 안 됨
    public var isOnline: AnyPublisher<Bool, Never> {
        _isOnline.eraseToAnyPublisher()
    }
    
    /// 내부 상태 Subject
    private let _isOnline = CurrentValueSubject<Bool, Never>(false)
    
    /// 초기화
    init() {
        startMonitoring()
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    /// 네트워크 모니터링 시작
    private func startMonitoring() {
        // 초기 상태 설정
        _isOnline.send(pathMonitor.currentPath.status == .satisfied)
        
        // 경로 변경 감지
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied
            self?._isOnline.send(isOnline)
        }
        
        // 모니터링 시작
        pathMonitor.start(queue: monitorQueue)
    }
}

