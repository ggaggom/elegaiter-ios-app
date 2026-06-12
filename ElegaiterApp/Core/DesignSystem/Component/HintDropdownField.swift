//
//  HintDropdownField.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// 비밀번호 힌트 드롭다운 필드 컴포넌트
/// 
/// Android의 `HintDropdownField`를 SwiftUI로 변환
/// - RoundedInputField와 동일한 스타일
/// - 커스텀 드롭다운 메뉴 (둥근 모서리, Divider 포함)
/// - 확장 시 배경색 변경
struct HintDropdownField: View {
    /// 선택된 힌트 (PasswordHint enum)
    @Binding var selectedHint: PasswordHint?
    /// 힌트 선택 콜백
    let onHintSelected: (PasswordHint) -> Void
    /// 라벨 텍스트 (기본값: 로컬라이즈된 "비밀번호 힌트")
    var labelText: String = "auth_pw_hint".localized()
    
    /// 비밀번호 힌트 목록
    /// 
    /// AppConstants에서 일원화된 힌트 목록 사용
    private var hints: [PasswordHint] {
        AppConstants.passwordHints
    }
    
    /// 선택된 힌트의 로컬라이즈된 텍스트
    private var selectedHintText: String {
        guard let hint = selectedHint else {
            return ""
        }
        return AppConstants.localizedText(for: hint)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 라벨이 있을 때만 표시
            if !labelText.isEmpty {
                Text(labelText)
                    .typography(ElegaiterTypography.Label3)
                    .foregroundColor(.secondary)
            }
            
            // 드롭다운 필드 (Menu 사용)
            Menu {
                ForEach(hints, id: \.self) { hint in
                    Button(action: {
                        onHintSelected(hint)
                    }) {
                        Text(AppConstants.localizedText(for: hint))
                    }
                }
            } label: {
                HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        if selectedHint == nil {
                            Text("auth_pw_hint".localized())
                                .typography(ElegaiterTypography.Body3)
                                .foregroundColor(ElegaiterColors.Text.sub1)
                        } else {
                            Text(selectedHintText)
                                .typography(ElegaiterTypography.Body3)
                                .foregroundColor(ElegaiterColors.Text.main)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image("IcDropDown")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .frame(height: 56)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(ElegaiterColors.Stroke.weak, lineWidth: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
        .localized() // 언어 변경 시 자동 업데이트
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedHint: PasswordHint? = nil
        
        var body: some View {
            HintDropdownField(
                selectedHint: $selectedHint,
                onHintSelected: { hint in
                    selectedHint = hint
                }
            )
            .padding()
        }
    }
    
    return PreviewWrapper()
}
