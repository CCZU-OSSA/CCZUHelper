//
//  AppDateFormatting.swift
//  CCZUHelper
//
//  Created by Codex on 2026/2/16.
//

import Foundation

/// 统一日期格式化入口，避免业务层分散创建 DateFormatter。
enum AppDateFormatting {
    static func mediumDateString(from date: Date) -> String {
        formatter { formatter in
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }
        .string(from: date)
    }

    static func yearMonthChineseString(from date: Date) -> String {
        formatter { formatter in
            formatter.dateFormat = "yyyy年M月"
        }
        .string(from: date)
    }

    static func monthDayHourMinuteString(from date: Date) -> String {
        formatter { formatter in
            formatter.dateFormat = "MM-dd HH:mm"
        }
        .string(from: date)
    }

    /// 支持格式: "2025年12月18日 18:30--20:30" 或 "2025年12月18日 18:30"
    static func parseChineseExamDateTime(_ timeString: String) -> Date? {
        let components = timeString.components(separatedBy: " ")
        guard components.count >= 2 else { return nil }

        let datePart = components[0]
        let timePart = components[1].components(separatedBy: "--")[0]
        let merged = "\(datePart) \(timePart)"

        return formatter { formatter in
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        }
        .date(from: merged)
    }

    /// 每次创建独立 formatter，避免 thread-local 缓存与并发任务线程漂移之间的耦合。
    private static func formatter(configure: (DateFormatter) -> Void) -> DateFormatter {
        let formatter = DateFormatter()
        configure(formatter)
        return formatter
    }
}
