//
//  RoundedTextArea.swift
//  ElegaiterApp
//
//  Created on 2026-05-29.
//

import SwiftUI

/// 둥근 모서리 멀티라인 텍스트 영역
///
/// Android의 `RoundedTextArea`를 SwiftUI로 변환
struct RoundedTextArea: View {
    @Binding var value: String
    let placeholder: String
    let onValueChange: (String) -> Void
    var minHeight: CGFloat = 140
    var maxHeight: CGFloat = 200
    var enabled: Bool = true
    var eventBorderColor: Color? = nil
    
    @FocusState private var isFocused: Bool
    
    private var borderColor: Color {
        if let eventBorderColor {
            return eventBorderColor
        }
        return isFocused ? ElegaiterColors.Green.green400 : ElegaiterColors.Stroke.weak
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if value.isEmpty {
                Text(placeholder)
                    .typography(ElegaiterTypography.Body3)
                    .foregroundColor(ElegaiterColors.Text.sub1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            
            TextEditor(text: $value)
                .typography(ElegaiterTypography.Body3)
                .foregroundColor(ElegaiterColors.Text.main)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .disabled(!enabled)
                .focused($isFocused)
                .onChange(of: value) { newValue in
                    onValueChange(newValue)
                }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: minHeight, maxHeight: maxHeight)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(borderColor, lineWidth: 1)
        )
        .cornerRadius(20)
    }
}
