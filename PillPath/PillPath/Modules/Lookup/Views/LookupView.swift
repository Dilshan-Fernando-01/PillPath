//
//  LookupView.swift
//  PillPath — Lookup Module
//
//  Search Medication screen.
//  Matches Figma: search bar → suggestions chips → results list.
//

import SwiftUI

struct LookupView: View {

    @StateObject private var viewModel = LookupViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.top, AppSpacing.md)
                        .padding(.bottom, AppSpacing.sm)

                    // Body
                    if viewModel.isSearching {
                        loadingView
                            .frame(maxHeight: .infinity)
                    } else if let err = viewModel.errorMessage {
                        errorView(err)
                            .frame(maxHeight: .infinity)
                    } else if viewModel.searchText.isEmpty {
                        suggestionsView
                    } else if viewModel.searchResults.isEmpty {
                        noResultsView
                            .frame(maxHeight: .infinity)
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search Medication")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                }
            }
            .sheet(item: $viewModel.selectedResult) { result in
                MedicationInfoView(result: result)
            }
        }
        // Replicate bottom nav bar so it's visible in the full-screen cover
        .safeAreaInset(edge: .bottom, spacing: 0) {
            lookupNavBar
        }
        .onAppear { searchFocused = true }
    }

    // MARK: - Lookup Nav Bar (mirrors main tab bar, "Lookup" active)
    // Each item dismisses Lookup and deep-links back to the correct tab via Notification.

    private var lookupNavBar: some View {
        HStack(spacing: 0) {
            navBarItem(icon: "house", label: "HOME")      { postTabSwitch(.home) }
            navBarItem(icon: "cross.circle", label: "MEDS") { postTabSwitch(.medications) }

            // FAB (active — stays on Lookup)
            Spacer().frame(width: 72)

            navBarItem(icon: "qrcode.viewfinder", label: "SCAN") { postTabSwitch(.scan) }
            navBarItem(icon: "calendar", label: "ACTIVITY")      { postTabSwitch(.activity) }
        }
        .frame(height: 64)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .appCardShadow()
        .padding(.horizontal, AppSpacing.md)
        .overlay(alignment: .top) {
            // Active Lookup FAB
            ZStack {
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: 56, height: 56)
                    .appButtonShadow()
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .offset(y: -16)
        }
    }

    private func navBarItem(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textSecondary)
                Text(label)
                    .font(AppFont.label())
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func postTabSwitch(_ tab: AppTab) {
        dismiss()
        let notif: Notification.Name = tab == .home ? .switchToHomeTab : .switchToTab
        NotificationCenter.default.post(name: notif, object: tab)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.textSecondary)
                .font(.system(size: 16))

            TextField("Enter medication name (e.g., Paracetamol)", text: $viewModel.searchText)
                .font(AppFont.body())
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.search(query: viewModel.searchText) }
                }
                .onChange(of: viewModel.searchText) { _, newValue in
                    viewModel.onSearchTextChanged(newValue)
                }

            if !viewModel.searchText.isEmpty {
                Button { viewModel.clearSearch() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textSecondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(searchFocused ? Color.brandPrimary : Color.appBorder, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: searchFocused)
    }

    // MARK: - Suggestions

    private var suggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search Medication")
                        .font(AppFont.title())
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)
                    Text("Find information about your medicine")
                        .font(AppFont.body())
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)

                // Suggested chips
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("SUGGESTED MEDICATIONS")
                        .font(AppFont.label())
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, AppSpacing.md)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: AppSpacing.sm
                    ) {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            Button {
                                viewModel.searchText = suggestion
                                viewModel.onSearchTextChanged(suggestion)
                            } label: {
                                Text(suggestion)
                                    .font(AppFont.body())
                                    .foregroundStyle(Color.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .padding(.horizontal, AppSpacing.md)
                                    .background(Color.appSurface)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.md)
                                            .stroke(Color.appBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Count header
                HStack {
                    Text("SEARCH RESULTS")
                        .font(AppFont.label())
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Text("\(viewModel.searchResults.count) items found")
                        .font(AppFont.label())
                        .foregroundStyle(Color.brandPrimary)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)

                // Result rows
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, result in
                        Button {
                            viewModel.selectedResult = result
                        } label: {
                            SearchResultRow(result: result)
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.searchResults.count - 1 {
                            Divider()
                                .padding(.leading, AppSpacing.xl + AppSpacing.md)
                        }
                    }
                }
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .appCardShadow()
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(Color.brandPrimary)
            Text("Searching…")
                .font(AppFont.body())
                .foregroundStyle(Color.textSecondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            Text(message)
                .font(AppFont.body())
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
            Button {
                Task { await viewModel.search(query: viewModel.searchText) }
            } label: {
                Text("Try Again")
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
            }
        }
    }

    private var noResultsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.textSecondary.opacity(0.4))
            Text("No results for \"\(viewModel.searchText)\"")
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Text("Try a different name or check the spelling.")
                .font(AppFont.caption())
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - Search Result Row

struct SearchResultRow: View {

    let result: MedicationSearchResult

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Colored icon based on pharm class
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: "pill.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(result.brandName)
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                if let indication = result.indications?.truncated(to: 70) {
                    Text(indication)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
    }

    private var iconColor: Color {
        let cls = result.pharmClass.first?.lowercased() ?? ""
        if cls.contains("analges") || cls.contains("anti-inflam") { return Color.semanticError }
        if cls.contains("antibiotic") || cls.contains("antibacter") { return Color.semanticInfo }
        if cls.contains("cardiovas") || cls.contains("antihypert") { return Color.brandPrimary }
        if cls.contains("antidia") || cls.contains("biguanide") { return Color.semanticSuccess }
        return Color.brandAccent
    }
}

// MARK: - String truncation helper

private extension String {
    func truncated(to length: Int) -> String {
        count > length ? String(prefix(length)) + "…" : self
    }
}
