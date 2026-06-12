//
//  PasswordInputField.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 비밀번호 입력 필드 컴포넌트 (라벨 없음)
/// 
/// Android의 `PasswordInputField`를 SwiftUI로 변환
/// - 비밀번호 마스킹 처리
/// - 비밀번호 표시/숨김 토글 기능
/// - 이벤트 테두리 색상 지원 (성공/에러 상태 표시)
struct PasswordInputField: View {
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
    
    @State private var passwordVisible: Bool = false
    @FocusState private var isFocused: Bool
    
    /// 마지막으로 콜백을 호출한 값 (중복 호출 방지)
    @State private var lastCallbackValue: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                // 플레이스홀더
                if value.isEmpty {
                    Text(placeholder)
                        .typography(ElegaiterTypography.Body3)
                        .foregroundColor(ElegaiterColors.Text.sub1)
                }
                
                // 비밀번호 입력 필드 (표시/숨김 토글)
                Group {
                    if passwordVisible {
                        TextField("", text: $value)
                            .keyboardType(.default)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    } else {
                        SecureField("", text: $value)
                    }
                }
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
            
            // 비밀번호 표시/숨김 토글 버튼
            Button(action: {
                passwordVisible.toggle()
            }) {
                Image(passwordVisible ? "Visibility" : "VisibilityOff")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(ElegaiterColors.Text.sub2)
            }
            .padding(.leading, 8)
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
        PasswordInputField(
            value: .constant(""),
            placeholder: "비밀번호를 입력해주세요",
            onValueChange: { _ in }
        )
        
        PasswordInputField(
            value: .constant("password123"),
            placeholder: "비밀번호 확인",
            onValueChange: { _ in },
            eventBorderColor: ElegaiterColors.Status.success
        )
        
        PasswordInputField(
            value: .constant("wrong"),
            placeholder: "비밀번호 확인",
            onValueChange: { _ in },
            eventBorderColor: ElegaiterColors.Status.error
        )
        
        PasswordInputField(
            value: .constant(""),
            placeholder: "비밀번호",
            onValueChange: { _ in },
            enabled: false
        )
    }
    .padding()
}
