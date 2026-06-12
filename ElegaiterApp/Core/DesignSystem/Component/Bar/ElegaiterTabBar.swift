//
//  ElegaiterTabBar.swift
//  ElegaiterApp
//
//  Created on 2025-12-05. IKWTDH 🚀
//

/// Floating/Bubble 스타일의 커스텀 탭바 컴포넌트
/// https://www.youtube.com/watch?v=0nc4Zm1w3AQ

import SwiftUI
import os.log

struct ElegaiterTabBar: View {
    struct TabItem: Identifiable {
        let id: Int
        let title: String
        let icon: String
        let selectedIcon: String?
        let onClick: () -> Void
    }
    
    let items: [TabItem]
    /// 현재 선택된 탭의 ID
    let selectedTabId: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                TabBarButton(
                    item: item,
                    isSelected: item.id == selectedTabId
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        item.onClick()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(red: 0, green: 0, blue: 0, opacity: 0.8)) // #000000CC (204/255 = 0.8)
                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.302), radius: 8, x: 0, y: 4) // box-shadow: 0px 4px 8px 0px #0000004D (77/255 = 0.302)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

/// 개별 탭 버튼 컴포넌트
private struct TabBarButton: View {
    let item: ElegaiterTabBar.TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // 에셋 이미지 사용
                Image(isSelected ? (item.selectedIcon ?? item.icon) : item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                Text(item.title)
                    .typography(ElegaiterTypography.Caption2)
                    .foregroundColor(isSelected ? ElegaiterColors.Green.green400 : Color(white: 1.0, opacity: 0.6)) // 선택: Green400, 일반: #FFFFFF99 (153/255 = 0.6)
                    .padding(.top, 2)
            }
            .padding(.top, 10)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityHint(isSelected ? "선택된 탭" : "탭 선택")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    struct PreviewWrapper: View {
        private static let logger = Logger(subsystem: "com.elegaiter.app", category: "ElegaiterTabBar+Preview")
        @State private var selectedTabId: Int = 0

        let items: [ElegaiterTabBar.TabItem] = [
            ElegaiterTabBar.TabItem(
                id: 0,
                title: "HOME",
                icon: "IcHomeNormal",
                selectedIcon: "IcHomeSelected",
                onClick: {
                    Self.logger.debug("Selected tab: 0")
                }
            ),
            ElegaiterTabBar.TabItem(
                id: 1,
                title: "RECORD",
                icon: "IcRecordNormal",
                selectedIcon: "IcRecordSelected",
                onClick: {
                    Self.logger.debug("Selected tab: 1")
                }
            ),
            ElegaiterTabBar.TabItem(
                id: 2,
                title: "MY",
                icon: "IcMyNormal",
                selectedIcon: "IcMySelected",
                onClick: {
                    Self.logger.debug("Selected tab: 2")
                }
            )
        ]
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    ElegaiterTabBar(
                        items: items,
                        selectedTabId: selectedTabId
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}

