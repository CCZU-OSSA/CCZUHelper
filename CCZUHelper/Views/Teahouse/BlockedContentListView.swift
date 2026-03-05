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
            case .users: return "blocked_content.segment.users".localized
            case .posts: return "blocked_content.segment.posts".localized
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
                Picker("blocked_content.picker_label".localized, selection: $selectedSegment) {
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
                        Text("blocked_content.load_failed".localized)
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("common.retry".localized) {
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
        .navigationTitle("blocked_content.nav_title".localized)
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
        Section("blocked_content.section.users".localized) {
            if blockedUsers.isEmpty {
                Text("blocked_content.empty.users".localized)
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
                        Button("blocked_content.action.unblock".localized) {
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
        Section("blocked_content.section.posts".localized) {
            if blockedPosts.isEmpty {
                Text("blocked_content.empty.posts".localized)
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
                            Text(String(format: "blocked_content.post.author".localized, post.author))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("blocked_content.action.unblock".localized) {
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

