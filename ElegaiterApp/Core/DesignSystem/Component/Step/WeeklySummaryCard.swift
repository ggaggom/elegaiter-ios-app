//
//  WeeklySummaryCard.swift
//  ElegaiterApp
//
//  Created on 2025-11-24.
//

import SwiftUI
import ElegaiterSDK

/// 주간 요약 카드 컴포넌트
/// 
/// Android의 `WeeklySummaryCard`를 SwiftUI로 변환
/// - 주간 총 걸음 수 및 보행 유형 통계 표시
/// - 보행 패턴 기반 피드백 제공
struct WeeklySummaryCard: View {
    /// 주간 총 걸음 수
    let weeklyTotalSteps: Int
    /// 주간 보행 유형 통계
    let weeklyStepTypeStats: StepTypeStatistics?
    
    var body: some View {
        VStack(spacing: 0) {
            if let stats = weeklyStepTypeStats {
                VStack(alignment: .leading, spacing: 0) {
                    // StepSummary 콘텐츠
                    StepSummaryContent(
                        totalSteps: weeklyTotalSteps,
                        stats: stats
                    )
                    
                    // 피드백 카드 (상단 여백 16)
                    Spacer()
                        .frame(height: 16)
                    
                    WeeklyFeedbackCard(stats: stats)
                }
                .padding(12)
            }
        }
        .background(ElegaiterColors.Green.green50)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ElegaiterColors.Green.green400, lineWidth: 1)
        )
        .cornerRadius(12)
        .padding(.top, 20)
        .padding(.horizontal, 16)
        .localized() // 언어 변경 시 자동 업데이트
    }
    
    // MARK: - StepSummary Content
    
    @ViewBuilder
    private func StepSummaryContent(
        totalSteps: Int,
        stats: StepTypeStatistics
    ) -> some View {
        StepSummary(
            title: "recent_7days_total_steps".localized(),
            totalSteps: totalSteps,
            items: [
                StepItem(
                    label: "exercise_walk".localized(),
                    percentage: stats.walking.ratio,
                    color: .green
                ),
                StepItem(
                    label: "exercise_unknown".localized(),
                    percentage: stats.limping.ratio,
                    color: .yellow
                ),
                StepItem(
                    label: "exercise_run".localized(),
                    percentage: stats.running.ratio,
                    color: .orange
                )
            ]
        )
    }
    
    // MARK: - Feedback Card
    
    @ViewBuilder
    private func WeeklyFeedbackCard(stats: StepTypeStatistics) -> some View {
        let feedback = generateFeedback(stats: stats)
        
        HStack(alignment: .center, spacing: 8) {
            Image("IcFire")
                .resizable()
                .renderingMode(.original)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feedback.headline)
                    .typography(ElegaiterTypography.Label3)
                    .foregroundColor(ElegaiterColors.Text.main)
                
                Text(feedback.subtext)
                    .typography(ElegaiterTypography.Caption1)
                    .foregroundColor(ElegaiterColors.Text.sub2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(height: 57)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Feedback Generation
    
    private struct Feedback {
        let headline: String
        let subtext: String
    }
    
    private func generateFeedback(stats: StepTypeStatistics) -> Feedback {
        let walkingRatio = stats.walking.ratio
        let runningRatio = stats.running.ratio
        
        if runningRatio > 0.50 {
            return Feedback(
                headline: "recent_7days_running_high".localized(),
                subtext: "recent_7days_running_high_motivation".localized()
            )
        } else if walkingRatio > 0.70 {
            return Feedback(
                headline: "recent_7days_walking_high".localized(),
                subtext: "recent_7days_walking_high_motivation".localized()
            )
        } else {
            return Feedback(
                headline: "recent_7days_none_high".localized(),
                subtext: "recent_7days_none_high_motivation".localized()
            )
        }
    }
}

#Preview {
    WeeklySummaryCard(
        weeklyTotalSteps: 50000,
        weeklyStepTypeStats: StepTypeStatistics(
            walking: PerGaitTypeStat(count: 30000, ratio: 0.6, totalDurationS: 0),
            running: PerGaitTypeStat(count: 15000, ratio: 0.3, totalDurationS: 0),
            limping: PerGaitTypeStat(count: 5000, ratio: 0.1, totalDurationS: 0)
        )
    )
    .padding()
}
