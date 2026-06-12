//
//  AgreeAllButton.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 전체 동의 버튼 컴포넌트
/// 
/// Android의 `AgreeAllButton`을 SwiftUI로 변환
/// - 전체 약관 동의/해제 기능
/// - 체크박스와 텍스트를 포함한 버튼 형태
struct AgreeAllButton: View {
    /// 체크 상태
    @Binding var checked: Bool
    /// 체크 상태 변경 콜백
    let onCheckedChange: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            checked.toggle()
            onCheckedChange(checked)
        }) {
            HStack(spacing: 8) {
                CustomCheckbox(
                    checked: $checked,
                    onCheckedChange: onCheckedChange,
                    uncheckedBackgroundColor: .white
                )
                
                Text("sign_up_agree_all".localized())
                    .typography(ElegaiterTypography.Headline6)
                    .foregroundColor(ElegaiterColors.Text.main)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 13)
            .padding(.horizontal, 8)
            .background(ElegaiterColors.Background.light)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ElegaiterColors.Stroke.weak, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var checked = false
        
        var body: some View {
            VStack(spacing: 20) {
                AgreeAllButton(
                    checked: $checked,
                    onCheckedChange: { newValue in
                        checked = newValue
                    }
                )
                
                Text("체크 상태: \(checked ? "동의" : "미동의")")
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
