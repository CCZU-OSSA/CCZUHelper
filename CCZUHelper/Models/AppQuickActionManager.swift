//
//  AppQuickActionManager.swift
//  CCZUHelper
//
//  Created by Codex on 2026/03/02.
//

import Foundation
#if os(iOS)
import UIKit
#endif

extension Notification.Name {
    static let appQuickActionRouteReceived = Notification.Name("AppQuickActionRouteReceived")
}

enum AppQuickActionRoute: String {
    case schedule
    case grades
    case teahouse
    case search
}

enum AppQuickActionManager {
    private static let pendingRouteKey = "quickaction.pending.route"

    #if os(iOS)
    private static let typePrefix = "com.stuwang.edupal.quickaction."
    #endif

    static func savePending(route: AppQuickActionRoute) {
        UserDefaults.standard.set(route.rawValue, forKey: pendingRouteKey)
    }

    static func consumePendingRoute() -> AppQuickActionRoute? {
        guard let raw = UserDefaults.standard.string(forKey: pendingRouteKey),
              let route = AppQuickActionRoute(rawValue: raw) else {
            return nil
        }
        UserDefaults.standard.removeObject(forKey: pendingRouteKey)
        return route
    }

    static func dispatch(route: AppQuickActionRoute) {
        NotificationCenter.default.post(name: .appQuickActionRouteReceived, object: route.rawValue)
    }

    #if os(iOS)
    static func configureShortcutItems() {
        UIApplication.shared.shortcutItems = [
            UIApplicationShortcutItem(
                type: typePrefix + AppQuickActionRoute.schedule.rawValue,
                localizedTitle: "tab.schedule".localized,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .date),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: typePrefix + AppQuickActionRoute.grades.rawValue,
                localizedTitle: "intent.open_grades.title".localized,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .task),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: typePrefix + AppQuickActionRoute.teahouse.rawValue,
                localizedTitle: "tab.teahouse".localized,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .message),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: typePrefix + AppQuickActionRoute.search.rawValue,
                localizedTitle: "tab.search".localized,
                localizedSubtitle: nil,
                icon: UIApplicationShortcutIcon(type: .search),
                userInfo: nil
            ),
        ]
    }

    static func route(from shortcutItem: UIApplicationShortcutItem) -> AppQuickActionRoute? {
        guard shortcutItem.type.hasPrefix(typePrefix) else { return nil }
        let raw = String(shortcutItem.type.dropFirst(typePrefix.count))
        return AppQuickActionRoute(rawValue: raw)
    }
    #endif
}
