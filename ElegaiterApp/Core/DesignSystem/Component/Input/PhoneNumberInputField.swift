//
//  PhoneNumberInputField.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import os.log

/// 전화번호 전용 입력 필드
/// 
/// 하이픈 삭제 문제를 해결하기 위한 커스텀 입력 필드
/// - 숫자만 입력받음
/// - [비활성화] 자동 포맷팅 적용 (주석 처리됨)
/// - [비활성화] 하이픈 삭제 시 해당 위치의 숫자도 함께 삭제 (주석 처리됨)
struct PhoneNumberInputField: View {
    /// 라벨 텍스트
    let labelText: String
    /// 입력 값 (포맷팅된 형태)
    @Binding var value: String
    /// 플레이스홀더 텍스트
    let placeholder: String
    /// 값 변경 콜백
    let onValueChange: (String) -> Void
    /// 활성화 여부
    var enabled: Bool = true
    
    /// 이전 값 저장 (iOS 16 호환)
    @State private var previousValue: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 라벨
            Text(labelText)
                .typography(ElegaiterTypography.Label3)
                .foregroundColor(ElegaiterColors.Text.sub1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 6)
            
            // 입력 필드
            RoundedInputField(
                value: $value,
                placeholder: placeholder,
                onValueChange: { newValue in
                    handleValueChange(oldValue: previousValue, newValue: newValue)
                },
                enabled: enabled
            )
            .keyboardType(.numberPad)
            .onAppear {
                previousValue = value
            }
        }
    }
    
    /// 값 변경 처리
    /// 
    /// [현재 비활성화] 하이픈 삭제를 감지하고, 하이픈이 삭제된 경우 해당 위치의 숫자도 함께 삭제
    /// [현재 비활성화] 비동기로 처리하여 메인 스레드 블로킹 방지
    /// 
    /// 현재는 숫자만 추출하여 그대로 사용 (포맷팅 비활성화)
    private func handleValueChange(oldValue: String, newValue: String) {
        // 값이 변경되지 않았으면 무시 (중복 호출 방지)
        guard oldValue != newValue else { return }
        
        // 숫자만 추출하여 그대로 사용 (포맷팅 비활성화)
        let numbers = PhoneNumberFormatter.extractNumbers(newValue)
        // 최대 11자리까지만 입력 허용
        let limitedNumbers = String(numbers.prefix(11))
        
        // 포맷팅 없이 숫자만 그대로 사용
        if limitedNumbers != value {
            value = limitedNumbers
        }
        
        // 이전 값 업데이트 (다음 onChange를 위해)
        previousValue = limitedNumbers
        
        // 콜백 호출
        onValueChange(limitedNumbers)
        
        // ========== [주석 처리됨] 자동 하이픈 포맷팅 기능 ==========
        // 나중에 다시 활성화할 수 있도록 코드는 유지하되 주석 처리
        /*
        // 포맷팅 로직을 비동기로 처리하여 Hang 방지
        Task { @MainActor in
            // 숫자만 추출
            let oldNumbers = PhoneNumberFormatter.extractNumbers(oldValue)
            let newNumbers = PhoneNumberFormatter.extractNumbers(newValue)
            
            var finalFormatted: String
            
            // 숫자가 실제로 줄어들었는지 확인 (삭제 동작)
            if newNumbers.count < oldNumbers.count {
                // 숫자가 줄어든 경우: 정상적인 삭제
                finalFormatted = PhoneNumberFormatter.format(newNumbers)
            } else if newNumbers.count == oldNumbers.count {
                // 숫자가 같은데 값이 다른 경우: 하이픈 삭제 시도
                let oldFormatted = PhoneNumberFormatter.format(oldNumbers)
                if newValue != oldFormatted && newValue.count < oldValue.count {
                    // 하이픈이 삭제된 것으로 보임
                    // 마지막 숫자를 삭제한 것으로 처리
                    let removedNumbers = String(oldNumbers.dropLast())
                    finalFormatted = PhoneNumberFormatter.format(removedNumbers)
                } else {
                    // 포맷팅만 다른 경우 (이미 포맷팅된 값)
                    finalFormatted = PhoneNumberFormatter.format(newNumbers)
                }
            } else {
                // 숫자가 늘어난 경우: 정상적인 입력
                let limitedNumbers = String(newNumbers.prefix(11))
                finalFormatted = PhoneNumberFormatter.format(limitedNumbers)
            }
            
            // 포맷팅된 결과가 현재 값과 다를 때만 업데이트
            if finalFormatted != value {
                value = finalFormatted
            }
            
            // 이전 값 업데이트 (다음 onChange를 위해)
            previousValue = finalFormatted
            
            // 콜백 호출
            onValueChange(finalFormatted)
        }
        */
    }
}

#Preview {
    struct PreviewWrapper: View {
        private static let logger = Logger(subsystem: "com.elegaiter.app", category: "PhoneNumberInputField+Preview")
        @State private var phone = ""

        var body: some View {
            PhoneNumberInputField(
                labelText: "전화번호",
                value: $phone,
                placeholder: "전화번호를 입력해 주세요",
                onValueChange: { newValue in
                    Self.logger.debug("전화번호 변경: \(newValue)")
                }
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}

