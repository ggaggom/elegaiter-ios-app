//
//  TempAuthStorage.swift
//  ElegaiterApp
//
//  Created on 2025-11-26.
//

import Foundation

/// 회원정보 수정 진입 전 재인증 비밀번호 임시 저장소
///
/// Android의 `TempAuthStorage`와 동일 — 메모리에만 보관하며 consume 시 즉시 삭제
final class TempAuthStorage {
    static let shared = TempAuthStorage()

    private var tempPassword: String?

    private init() {}

    func setPassword(_ password: String) {
        tempPassword = password
    }

    /// 저장된 비밀번호를 꺼내고 메모리에서 삭제 (1회용)
    func consumePassword() -> String? {
        let password = tempPassword
        tempPassword = nil
        return password
    }

    /// 사용 후 비밀번호 문자열 참조 제거
    func wipePassword(_ password: inout String?) {
        password = nil
    }
}
