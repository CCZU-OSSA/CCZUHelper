//
//  ReportUserView.swift
//  CCZUHelper
//
//  Created by Codex on 2026/3/1.
//

import SwiftUI

struct ReportUserView: View {
    @Environment(\.dismiss) private var dismiss

    let userId: String
    let username: String

    @StateObject private var teahouseService = TeahouseService()

    @State private var selectedReason = ""
    @State private var details = ""
    @State private var shouldBlockUser = false
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let reasons = [
        "骚扰/辱骂",
        "恶意广告",
        "不实信息",
        "色情/低俗内容",
        "仇恨/歧视言论",
        "其他"
    ]

    private var isValid: Bool {
        !selectedReason.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("举报用户")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("@\(username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("请选择举报原因，我们会尽快处理。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.clear)

                Section("举报原因") {
                    ForEach(reasons, id: \.self) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("补充说明（可选）") {
                    TextField("请描述具体情况", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("同时屏蔽该用户", isOn: $shouldBlockUser)
                }

                Section {
                    Button(action: submit) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text("提交")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .buttonBorderShape(.capsule)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("举报用户")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .cancel) {
                            dismiss()
                        }
                        .disabled(isSubmitting)
                    } else {
                        Button("取消") {
                            dismiss()
                        }
                        .disabled(isSubmitting)
                    }
                }
            }
            .alert("提交失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func submit() {
        guard isValid else { return }

        Task {
            isSubmitting = true
            defer { isSubmitting = false }

            do {
                try await teahouseService.reportUser(
                    reportedId: userId,
                    reason: selectedReason,
                    details: details
                )

                if shouldBlockUser {
                    try await teahouseService.blockUser(blockedId: userId)
                }

                dismiss()
            } catch AppError.notAuthenticated {
                errorMessage = "请先登录后再操作"
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

