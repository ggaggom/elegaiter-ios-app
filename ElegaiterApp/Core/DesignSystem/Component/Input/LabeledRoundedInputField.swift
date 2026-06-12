//
//  LabeledRoundedInputField.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 라벨이 있는 둥근 모서리 입력 필드 컴포넌트
/// 
/// Android의 `LabeledRoundedInputField`를 SwiftUI로 변환
/// - 라벨과 입력 필드를 함께 제공
/// - 둥근 모서리 스타일 적용
struct LabeledRoundedInputField: View {
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
    /// 이벤트 테두리 색상 (성공: 초록색, 에러: 빨간색)
    var eventBorderColor: Color? = nil
    /// 후행 아이콘
    var trailingIcon: (() -> AnyView)? = nil
    /// 최대 입력 길이 (nil이면 제한 없음)
    var maxLength: Int? = nil
    
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
                onValueChange: onValueChange,
                enabled: enabled,
                eventBorderColor: eventBorderColor,
                trailingIcon: trailingIcon,
                maxLength: maxLength
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LabeledRoundedInputField(
            labelText: "아이디",
            value: .constant(""),
            placeholder: "아이디를 입력해주세요",
            onValueChange: { _ in }
        )
        
        LabeledRoundedInputField(
            labelText: "이름",
            value: .constant("홍길동"),
            placeholder: "이름을 입력해주세요",
            onValueChange: { _ in },
            enabled: false
        )
        
        LabeledRoundedInputField(
            labelText: "에러 상태",
            value: .constant("에러 값"),
            placeholder: "에러 테두리 예시",
            onValueChange: { _ in },
            eventBorderColor: ElegaiterColors.Status.error
        )
    }
    .padding()
}
