//
//  CustomCheckbox.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 커스텀 체크박스 컴포넌트
/// 
/// Android의 `CustomCheckbox`를 SwiftUI로 변환
/// - 기본 체크박스 스타일 커스터마이징
/// - 체크되지 않은 상태의 배경색 설정 가능
struct CustomCheckbox: View {
    /// Binding을 사용하는 경우의 체크 상태
    @Binding private var checkedBinding: Bool
    /// 값을 직접 받는 경우의 체크 상태
    @State private var checkedState: Bool
    /// 외부에서 전달받은 checked 값 (Binding을 사용하지 않는 경우, onChange를 위해 저장)
    private let externalChecked: Bool
    /// Binding 사용 여부
    private let usesBinding: Bool
    /// 체크 상태 변경 콜백
    let onCheckedChange: (Bool) -> Void
    /// 체크되지 않은 상태의 배경색
    var uncheckedBackgroundColor: Color = .clear
    
    /// Binding을 사용하는 초기화 (기존 코드 호환)
    init(
        checked: Binding<Bool>,
        onCheckedChange: @escaping (Bool) -> Void,
        uncheckedBackgroundColor: Color = .clear
    ) {
        self._checkedBinding = checked
        self._checkedState = State(initialValue: false)
        self.externalChecked = false
        self.usesBinding = true
        self.onCheckedChange = onCheckedChange
        self.uncheckedBackgroundColor = uncheckedBackgroundColor
    }
    
    /// 값을 직접 받는 초기화 (안드로이드와 동일)
    init(
        checked: Bool,
        onCheckedChange: @escaping (Bool) -> Void,
        uncheckedBackgroundColor: Color = .clear
    ) {
        self._checkedBinding = .constant(false)
        self._checkedState = State(initialValue: checked)
        self.externalChecked = checked
        self.usesBinding = false
        self.onCheckedChange = onCheckedChange
        self.uncheckedBackgroundColor = uncheckedBackgroundColor
    }
    
    private var checked: Bool {
        usesBinding ? checkedBinding : checkedState
    }
    
    var body: some View {
        Button(action: {
            let newValue = !checked
            if usesBinding {
                checkedBinding = newValue
            } else {
                checkedState = newValue
            }
            onCheckedChange(newValue)
        }) {
            ZStack {
                // 배경색
                RoundedRectangle(cornerRadius: 4)
                    .fill(checked ? ElegaiterColors.Green.green400 : (uncheckedBackgroundColor == .clear ? .white : uncheckedBackgroundColor))
                    .frame(width: 20, height: 20)
                
                // 체크마크 아이콘 (선택 상태일 때만 표시)
                if checked {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(ElegaiterColors.Stroke.weak, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if !usesBinding {
                checkedState = externalChecked
            }
        }
        .id(externalChecked) // 외부 값이 변경되면 뷰를 다시 생성하여 상태 동기화
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var checked1 = true
        @State private var checked2 = false
        @State private var checked3 = true
        
        var body: some View {
    VStack(spacing: 20) {
        CustomCheckbox(
                    checked: checked1,
                    onCheckedChange: { checked1 = $0 }
        )
        
        CustomCheckbox(
                    checked: checked2,
                    onCheckedChange: { checked2 = $0 }
        )
        
        HStack {
            CustomCheckbox(
                        checked: checked3,
                        onCheckedChange: { checked3 = $0 }
            )
            Text("자동 로그인")
        }
    }
    .padding()
        }
    }
    
    return PreviewWrapper()
}
