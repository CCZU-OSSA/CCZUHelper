//
//  PostDetailModeration.swift
//  CCZUHelper
//
//  Created by Codex on 2026/3/5.
//

import SwiftUI
import SwiftData

/// 帖子详情页面的管理功能扩展
extension PostDetailView {
    // MARK: - Moderation Actions

    /// 屏蔽帖子作者
    func blockAuthor() {
        guard let authorId = post.authorId else { return }

        Task {
            do {
                try await teahouseService.blockUser(blockedId: authorId)
                await MainActor.run {
                    NotificationCenter.default.post(name: .teahouseUserBlocked, object: authorId)
                }
            } catch AppError.notAuthenticated {
                await MainActor.run {
                    moderationErrorMessage = "teahouse.moderation.not_authenticated".localized
                    showModerationError = true
                }
            } catch {
                await MainActor.run {
                    moderationErrorMessage = error.localizedDescription
                    showModerationError = true
                }
            }
        }
    }

    /// 删除当前帖子
    func deleteCurrentPost() {
        guard isOwnPost else { return }

        Task {
            do {
                try await teahouseService.deletePost(postId: post.id)
                await MainActor.run {
                    modelContext.delete(post)
                    try? modelContext.save()
                    NotificationCenter.default.post(name: .teahousePostDeleted, object: post.id)
                }
            } catch {
                await MainActor.run {
                    moderationErrorMessage = error.localizedDescription
                    showModerationError = true
                }
            }
        }
    }

    /// 屏蔽当前帖子
    func blockCurrentPost() {
        Task {
            do {
                try await teahouseService.blockPost(postId: post.id)
                await MainActor.run {
                    NotificationCenter.default.post(name: .teahousePostBlocked, object: post.id)
                }
            } catch AppError.notAuthenticated {
                await MainActor.run {
                    moderationErrorMessage = "teahouse.moderation.not_authenticated".localized
                    showModerationError = true
                }
            } catch {
                await MainActor.run {
                    moderationErrorMessage = error.localizedDescription
                    showModerationError = true
                }
            }
        }
    }
}
