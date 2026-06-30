//
//  ReviewDemoDataSeeder.swift
//  ElegaiterApp
//
//  App Store 심사용 reviewtest 계정에 미리 채워진 운동 기록을 1회 주입합니다.
//

import Foundation
import ElegaiterSDK
import os.log

/// App Store 심사용 데모 보행 기록 시더
enum ReviewDemoDataSeeder {
    private static let logger = Logger(subsystem: "com.elegaiter.app", category: "ReviewDemoDataSeeder")
    private static let sessionRepository = SessionRepositoryImpl()

    private enum Config {
        static let accountId = "reviewtest"
        static let seededKey = "review_demo_data_seeded_v1"
        static let date = "2026-06-30"

        struct RecordSpec {
            let resourceName: String
            let fileName: String
            let ulid: String
            let session: Int
            let elapsedTime: Int64
            let recordDateTime: String
            let exerciseInfo: ExerciseInfo
        }

        static let records: [RecordSpec] = [
            RecordSpec(
                resourceName: "step_stats_reviewtest_20260630_1_460",
                fileName: "step_stats_reviewtest_20260630_1_460.json",
                ulid: "01KWB9D79EJBQSDX7N8DARMHYC",
                session: 1,
                elapsedTime: 460,
                recordDateTime: "2026-06-30 09:30:00",
                exerciseInfo: ExerciseInfo(
                    speed: 4.0,
                    incline: 0.0,
                    duration: 8,
                    indexFoot: "left",
                    autoSave: false,
                    mood: ""
                )
            ),
            RecordSpec(
                resourceName: "step_stats_reviewtest_20260630_2_90",
                fileName: "step_stats_reviewtest_20260630_2_90.json",
                ulid: "01KWB9HE523XA8QMYAPX1QAA0Y",
                session: 2,
                elapsedTime: 90,
                recordDateTime: "2026-06-30 10:15:00",
                exerciseInfo: ExerciseInfo(
                    speed: 5.0,
                    incline: 0.0,
                    duration: 2,
                    indexFoot: "left",
                    autoSave: false,
                    mood: ""
                )
            )
        ]
    }

    /// reviewtest 계정 최초 로그인 시 데모 운동 기록을 주입합니다.
    static func seedIfNeeded(userId: String, sdk: ElegaiterSdk) async {
        guard userId == Config.accountId else { return }

        if UserDefaults.standard.bool(forKey: Config.seededKey) {
            return
        }

        if await hasAllDemoRecords(sdk: sdk) {
            UserDefaults.standard.set(true, forKey: Config.seededKey)
            return
        }

        var savedCount = 0

        for spec in Config.records {
            if await recordExists(fileName: spec.fileName, sdk: sdk) {
                savedCount += 1
                continue
            }

            guard let metrics = loadMetrics(resourceName: spec.resourceName) else {
                logger.error("데모 JSON 로드 실패: \(spec.resourceName, privacy: .public)")
                continue
            }

            let result = await sdk.gaitRecordManager.saveLocalRecord(
                metrics: metrics,
                exerciseInfo: spec.exerciseInfo,
                userId: userId,
                date: Config.date,
                sessionCount: spec.session,
                elapsedTime: spec.elapsedTime,
                ulid: spec.ulid,
                recordDateTime: spec.recordDateTime
            )

            switch result {
            case .success:
                savedCount += 1
                logger.debug("데모 기록 저장 성공: \(spec.fileName, privacy: .public)")
            case .failure(let error):
                logger.error("데모 기록 저장 실패: \(spec.fileName, privacy: .public) - \(error.localizedDescription, privacy: .public)")
            }
        }

        guard savedCount == Config.records.count else {
            logger.error("데모 기록 주입 미완료: \(savedCount)/\(Config.records.count)")
            return
        }

        await sessionRepository.saveLastSessionInfo(
            userId: userId,
            date: Config.date,
            count: Config.records.count
        )
        UserDefaults.standard.set(true, forKey: Config.seededKey)
        logger.debug("reviewtest 데모 기록 주입 완료")
    }

    private static func hasAllDemoRecords(sdk: ElegaiterSdk) async -> Bool {
        let listResult = await sdk.gaitRecordManager.listRecords()
        guard case .success(let records) = listResult else { return false }

        let existingFileNames = Set(records.map(\.fileName))
        let expectedFileNames = Set(Config.records.map(\.fileName))
        return expectedFileNames.isSubset(of: existingFileNames)
    }

    private static func recordExists(fileName: String, sdk: ElegaiterSdk) async -> Bool {
        let metaResult = await sdk.gaitRecordManager.loadRecordMetaData(fileName: fileName)
        guard case .success(let record) = metaResult, record != nil else {
            return false
        }
        return true
    }

    private static func loadMetrics(resourceName: String) -> GaitMetrics? {
        let candidateSubdirectories = [
            "Resources/ReviewDemo",
            "ReviewDemo"
        ]

        for subdirectory in candidateSubdirectories {
            if let url = Bundle.main.url(
                forResource: resourceName,
                withExtension: "json",
                subdirectory: subdirectory
            ),
               let metrics = decodeMetrics(from: url) {
                return metrics
            }
        }

        if let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
           let metrics = decodeMetrics(from: url) {
            return metrics
        }

        return nil
    }

    private static func decodeMetrics(from url: URL) -> GaitMetrics? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(GaitMetrics.self, from: data)
        } catch {
            logger.error("데모 JSON 디코딩 실패: \(url.lastPathComponent, privacy: .public) - \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
