//
//  Dropdown.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI

/// 드롭다운 컴포넌트
/// 
/// Android의 `Dropdown` 컴포넌트를 SwiftUI로 변환
/// - Threshold 값 선택에 사용 (0~50 범위)
/// - 4자리 문자열 포맷 ("0000" ~ "0050")
struct Dropdown: View {
    /// 선택된 값 (4자리 문자열)
    @Binding var selectedValue: String
    /// 값 변경 콜백
    let onValueChange: (String) -> Void
    
    /// Threshold 값 목록 (0~50)
    /// 
    /// Android의 `numberList = (0..50).map { it.toString().padStart(4, '0') }`와 동일
    private var numberList: [String] {
        (0...50).map { String(format: "%04d", $0) }
    }
    
    var body: some View {
        Picker("임계값 선택", selection: $selectedValue) {
            Text("선택해주세요").tag("")
            ForEach(numberList, id: \.self) { value in
                Text(value).tag(value)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: selectedValue) { newValue in
            onValueChange(newValue)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedValue = ""
        
        var body: some View {
            VStack(spacing: 20) {
                Dropdown(
                    selectedValue: $selectedValue,
                    onValueChange: { newValue in
                        selectedValue = newValue
                    }
                )
                
                Text("선택된 값: \(selectedValue.isEmpty ? "없음" : selectedValue)")
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
