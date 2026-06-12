//
//  LabeledPasswordInputField.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 라벨이 있는 비밀번호 입력 필드 컴포넌트
/// 
/// Android의 `LabeledPasswordInputField`를 SwiftUI로 변환
/// - 라벨과 비밀번호 입력 필드를 함께 제공
/// - 비밀번호 마스킹 처리
/// - 비밀번호 표시/숨김 토글 기능
struct LabeledPasswordInputField: View {
    /// 라벨 텍스트
    let labelText: String
    /// 입력 값
    @Binding var value: String
    /// 플레이스홀더 텍스트
    let placeholder: String
    /// 값 변경 콜백
    let onValueChange: (String) -> Void
    /// 활성화 여부
    var enabled: Bool = true
    /// 최대 입력 길이 (nil이면 제한 없음)
    var maxLength: Int? = nil
    /// 이벤트 테두리 색상 (성공: 초록색, 에러: 빨간색)
    var eventBorderColor: Color? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 라벨
            Text(labelText)
                .typography(ElegaiterTypography.Label3)
                .foregroundColor(ElegaiterColors.Text.sub1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 6)
            
            // 비밀번호 입력 필드
            PasswordInputField(
                value: $value,
                placeholder: placeholder,
                onValueChange: onValueChange,
                enabled: enabled,
                maxLength: maxLength,
                eventBorderColor: eventBorderColor
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LabeledPasswordInputField(
            labelText: "비밀번호",
            value: .constant(""),
            placeholder: "비밀번호를 입력해 주세요",
            onValueChange: { _ in }
        )
        
        LabeledPasswordInputField(
            labelText: "비밀번호 확인",
            value: .constant(""),
            placeholder: "비밀번호를 다시 입력해주세요",
            onValueChange: { _ in },
            enabled: false
        )
    }
    .padding()
}
