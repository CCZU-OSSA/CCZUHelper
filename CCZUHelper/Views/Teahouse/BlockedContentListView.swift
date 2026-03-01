//
//  BlockedContentListView.swift
//  CCZUHelper
//
//  Created by Codex on 2026/3/1.
//

import SwiftUI
import Kingfisher

struct BlockedContentListView: View {
    enum Segment: String, CaseIterable, Identifiable {
        case users
        case posts

        var id: String { rawValue }

        var title: String {
            switch self {
            case .users: return "屏蔽用户"
            case .posts: return "屏蔽帖子"
            }
        }
    }

    @StateObject private var teahouseService = TeahouseService()
    @State private var selectedSegment: Segment = .users
    @State private var blockedUsers: [BlockedUserInfo] = []
    @State private var blockedPosts: [BlockedPostInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Picker("屏蔽类型", selection: $selectedSegment) {
                    ForEach(Segment.allCases) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            if isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 16)
                }
            } else if let errorMessage {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("加载失败")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("重试") {
                            Task { await loadData() }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } else {
                switch selectedSegment {
                case .users:
                    usersSection
                case .posts:
                    postsSection
                }
            }
        }
        .navigationTitle("我屏蔽的")
        #if !os(macOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task {
            await loadData()
        }
        .refreshable {
            await loadData()
        }
    }

    private var usersSection: some View {
        Section("屏蔽用户") {
            if blockedUsers.isEmpty {
                Text("暂无屏蔽用户")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(blockedUsers) { user in
                    HStack(spacing: 12) {
                        avatarView(urlString: user.avatarUrl)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username)
                                .font(.body)
                            Text(user.blockedUserId)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("取消屏蔽") {
                            Task { await unblockUser(user) }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var postsSection: some View {
        Section("屏蔽帖子") {
            if blockedPosts.isEmpty {
                Text("暂无屏蔽帖子")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(blockedPosts) { post in
                    HStack(spacing: 12) {
                        Image(systemName: "doc.text.image")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .frame(width: 30, height: 30)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.title)
                                .font(.body)
                                .lineLimit(1)
                            Text("作者：\(post.author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("取消屏蔽") {
                            Task { await unblockPost(post) }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    @ViewBuilder
    private func avatarView(urlString: String?) -> some View {
        if let urlString, let url = URL(string: urlString) {
            KFImage(url)
                .placeholder {
                    ProgressView()
                }
                .resizable()
                .scaledToFill()
                .frame(width: 34, height: 34)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    private func loadData() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        do {
            async let users = teahouseService.fetchBlockedUsers()
            async let posts = teahouseService.fetchBlockedPosts()
            let (userData, postData) = try await (users, posts)
            await MainActor.run {
                blockedUsers = userData
                blockedPosts = postData
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func unblockUser(_ user: BlockedUserInfo) async {
        do {
            try await teahouseService.unblockUser(blockedId: user.blockedUserId)
            await MainActor.run {
                blockedUsers.removeAll { $0.blockedUserId == user.blockedUserId }
            }
            await MainActor.run {
                NotificationCenter.default.post(name: .teahouseUserBlocked, object: user.blockedUserId)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func unblockPost(_ post: BlockedPostInfo) async {
        do {
            try await teahouseService.unblockPost(postId: post.postId)
            await MainActor.run {
                blockedPosts.removeAll { $0.postId == post.postId }
            }
            await MainActor.run {
                NotificationCenter.default.post(name: .teahousePostBlocked, object: post.postId)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
}

