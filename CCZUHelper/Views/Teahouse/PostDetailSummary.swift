//
//  PostDetailSummary.swift
//  CCZUHelper
//
//  Created by Codex on 2026/3/5.
//

import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif

/// 帖子详情页面的摘要功能扩展
extension PostDetailView {
    // MARK: - Summary Functions

    /// 更新设备端摘要功能的可用性
    func updateSummarizationAvailability() {
        if let cached = OnDeviceSummaryAvailabilityCache.cachedAvailability() {
            self.canSummarizeOnDevice = cached
            if !OnDeviceSummaryAvailabilityCache.shouldRefresh() { return }
        }
        if isCheckingSummaryAvailability { return }
        isCheckingSummaryAvailability = true

        // TODO: 如果 SDK 提供了明确的 availability 枚举类型，例如：
        // switch model.availability {
        // case .available: self.canSummarizeOnDevice = true
        // case .unavailable(.deviceNotEligible): self.canSummarizeOnDevice = false
        // case .unavailable(.appleIntelligenceNotEnabled): self.canSummarizeOnDevice = false
        // case .unavailable(.modelNotReady): self.canSummarizeOnDevice = false
        // case .unavailable(_): self.canSummarizeOnDevice = false
        // }
        Task { @MainActor in
            #if canImport(FoundationModels)
            if #available(iOS 26.0, macOS 26.0, *) {
                let instructions = "teahouse.summary.instructions".localized
                let session = LanguageModelSession(instructions: instructions)

                // Use a lightweight probe to avoid reflection on FoundationModels internals.
                do {
                    _ = try await session.respond(to: "ping")
                    self.canSummarizeOnDevice = true
                    OnDeviceSummaryAvailabilityCache.save(true)
                } catch {
                    self.canSummarizeOnDevice = false
                    OnDeviceSummaryAvailabilityCache.save(false)
                }
            } else {
                self.canSummarizeOnDevice = false
                OnDeviceSummaryAvailabilityCache.save(false)
            }
            #else
            self.canSummarizeOnDevice = false
            OnDeviceSummaryAvailabilityCache.save(false)
            #endif
            self.isCheckingSummaryAvailability = false
        }
    }

    /// 使用设备端 AI 摘要帖子内容
    @MainActor
    func summarizePost() async {
        guard !isSummarizing else { return }
        isSummarizing = true
        summarizeError = nil
        summaryText = nil
        // Build the prompt from the post content and title
        let title = post.title
        let content = post.content
        let fullText = "teahouse.summary.prompt".localized(with: title, content)
        if #available(iOS 26.0, macOS 26.0, *) {
#if canImport(FoundationModels)
    do {
        let generator = try await TextGenerator.makeDefault()
        let request = TextGenerationRequest(prompt: fullText, maxTokens: 200)
        let response = try await generator.generate(request)
        self.summaryText = response.text
    } catch {
        self.summarizeError = error.localizedDescription
    }
#else
    // Fallback: 简单截断作为示例
    self.summaryText = "teahouse.summary.fallback_prefix".localized + String(fullText.prefix(120))
#endif
            self.showSummarySheet = true
        } else {
            self.summarizeError = "teahouse.summary.unsupported_system".localized
            self.showSummarySheet = true
        }
        isSummarizing = false
    }
}
