//
//  RoundedInputField.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 둥근 모서리 입력 필드 컴포넌트 (라벨 없음)
/// 
/// Android의 `RoundedInputField`를 SwiftUI로 변환
/// - 기본 텍스트 입력 필드
/// - 둥근 모서리 스타일 (32dp = 16pt)
/// - 포커스 시 테두리 색상 변경 (Green400)
/// - 이벤트 테두리 색상 지원 (성공/에러 상태 표시)
struct RoundedInputField: View {
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
    
    /// 포커스 상태 (외부에서 전달받거나 내부에서 관리)
    /// 상위 뷰에서 .focused() modifier를 사용하면 외부 FocusState가 적용됨
    /// 외부 FocusState가 없으면 내부 FocusState를 사용
    @FocusState private var isFocused: Bool
    
    /// 마지막으로 콜백을 호출한 값 (중복 호출 방지)
    @State private var lastCallbackValue: String = ""
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                // 플레이스홀더
                if value.isEmpty {
                    Text(placeholder)
                        .typography(ElegaiterTypography.Body3)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                }
                
                // 입력 필드
                TextField("", text: $value)
                    .typography(ElegaiterTypography.Body3)
                    .foregroundColor(ElegaiterColors.Text.main)
                    .disabled(!enabled)
                    .focused($isFocused)
                    .onChange(of: value) { newValue in
                        // 최대 길이 제한 적용
                        if let maxLength = maxLength, newValue.count > maxLength {
                            value = String(newValue.prefix(maxLength))
                            return
                        }
                        
                        // 값이 실제로 변경되었을 때만 콜백 호출 (중복 방지 및 Hang 방지)
                        if newValue != lastCallbackValue {
                            lastCallbackValue = newValue
                            // 비동기로 처리하여 메인 스레드 블로킹 방지
                            Task { @MainActor in
                                onValueChange(newValue)
                            }
                        }
                    }
                    .onAppear {
                        // 초기값 설정
                        lastCallbackValue = value
                    }
            }
            
            // 후행 아이콘
            if let trailingIcon = trailingIcon {
                trailingIcon()
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(borderColor, lineWidth: 1)
        )
    }
    
    /// 테두리 색상 계산
    private var borderColor: Color {
        if let eventColor = eventBorderColor {
            return eventColor
        }
        return isFocused ? ElegaiterColors.Green.green400 : ElegaiterColors.Stroke.weak
    }
}

#Preview {
    VStack(spacing: 20) {
        RoundedInputField(
            value: .constant(""),
            placeholder: "비밀번호 정답",
            onValueChange: { _ in }
        )
        
        RoundedInputField(
            value: .constant("답변"),
            placeholder: "답변을 입력하세요",
            onValueChange: { _ in },
            enabled: false
        )
        
        RoundedInputField(
            value: .constant("에러 상태"),
            placeholder: "에러 테두리 예시",
            onValueChange: { _ in },
            eventBorderColor: .red
        )
        
        RoundedInputField(
            value: .constant("아이콘 예시"),
            placeholder: "아이콘이 있는 입력 필드",
            onValueChange: { _ in },
            trailingIcon: {
                AnyView(
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                )
            }
        )
    }
    .padding()
}
