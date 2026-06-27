import SwiftUI

struct WorkflowRunRow: View {
    let run: WorkflowRun
    var now: Date = Date()

    private static let timeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        Button(action: openInBrowser) {
            HStack(spacing: 10) {
                statusDot
                    .frame(width: 10)

                repoInitialBadge

                branchBadge

                VStack(alignment: .leading, spacing: 2) {
                    Text(run.displayTitle ?? run.name ?? "Workflow")
                        .font(.callout.weight(.medium))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        if let repoName = run.repository?.fullName {
                            Text(repoName)
                                .foregroundStyle(.secondary)
                        }
                        if let branch = run.headBranch {
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Text(branch)
                                .foregroundStyle(.secondary)
                        }
                        if let duration = formattedDuration {
                            Text("·")
                                .foregroundStyle(.quaternary)
                            Text(duration)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .font(.caption)
                    .lineLimit(1)
                }

                Spacer()

                Text(
                    Self.timeFormatter.localizedString(
                        for: run.updatedAt, relativeTo: now)
                )
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var formattedDuration: String? {
        guard let startedAt = run.runStartedAt else { return nil }
        let endDate = run.status == .completed ? run.updatedAt : now
        let seconds = Int(endDate.timeIntervalSince(startedAt))
        guard seconds >= 0 else { return nil }
        if seconds < 60 {
            return "\(seconds)s"
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes < 60 {
            return remainingSeconds > 0 ? "\(minutes)m \(remainingSeconds)s" : "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
    }

    private var repoName: String {
        guard let fullName = run.repository?.fullName else { return "" }
        return fullName.split(separator: "/").last.map(String.init) ?? fullName
    }

    private var repoInitial: String {
        repoName.first.map { String($0).uppercased() } ?? "?"
    }

    /// Deterministic color per repo so each repo's badge stays consistent.
    private var repoColor: Color {
        let palette: [Color] = [.blue, .purple, .pink, .orange, .teal, .indigo, .green, .red, .mint, .cyan]
        let hash = repoName.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) }
        return palette[abs(hash) % palette.count]
    }

    private var repoInitialBadge: some View {
        Text(repoInitial)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 20, height: 20)
            .background(Circle().fill(repoColor.gradient))
    }

    /// Single-letter branch indicator: "m" for main/master, "d" for develop,
    /// otherwise the branch's first letter. Each gets a distinct color.
    private var branchStyle: (initial: String, color: Color)? {
        guard let branch = run.headBranch?.lowercased() else { return nil }
        switch branch {
        case "main", "master":
            return ("m", .green)
        case "develop", "dev":
            return ("d", .orange)
        default:
            return (branch.first.map(String.init) ?? "?", .gray)
        }
    }

    @ViewBuilder
    private var branchBadge: some View {
        if let style = branchStyle {
            Text(style.initial)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(style.color.gradient))
        }
    }

    @ViewBuilder
    private var statusDot: some View {
        switch (run.status, run.conclusion) {
        case (.completed, .success):
            Circle().fill(.green).frame(width: 8, height: 8)
        case (.completed, .failure), (.completed, .timedOut):
            Circle().fill(.red).frame(width: 8, height: 8)
        case (.completed, .cancelled):
            Circle().fill(.gray).frame(width: 8, height: 8)
        case (.inProgress, _), (.queued, _), (.waiting, _), (.pending, _), (.requested, _):
            Circle().fill(.orange).frame(width: 8, height: 8)
        default:
            Circle().fill(.secondary).frame(width: 8, height: 8)
        }
    }

    private func openInBrowser() {
        if let url = URL(string: run.htmlUrl) {
            NSWorkspace.shared.open(url)
        }
    }
}
