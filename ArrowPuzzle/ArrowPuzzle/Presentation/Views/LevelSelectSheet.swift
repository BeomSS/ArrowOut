#if DEBUG
import SwiftUI

/// Debug-only level navigator: supports direct numeric jump to any level (e.g., LV.1100)
/// plus a lightweight virtualized list of all levels up to the highest unlocked/cleared level.
public struct LevelSelectSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var jumpInputText: String = ""

    private var maxVisibleLevel: Int {
        max(1, max(viewModel.highestUnlockedLevel, viewModel.levelNumber))
    }

    public var body: some View {
        let theme = viewModel.theme

        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    // Direct jump & quick step controls for debugging arbitrary levels
                    Section("디버그 빠른 이동") {
                        HStack(spacing: 10) {
                            TextField("레벨 번호 입력 (예: 1100)", text: $jumpInputText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)

                            Button("이동") {
                                if let parsed = Int(jumpInputText.trimmingCharacters(in: .whitespaces)), parsed >= 1 {
                                    viewModel.startLevel(parsed)
                                    dismiss()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled((Int(jumpInputText.trimmingCharacters(in: .whitespaces)) ?? 0) < 1)
                        }

                        HStack(spacing: 8) {
                            quickStepButton(delta: -10, label: "-10")
                            quickStepButton(delta: -1, label: "-1")
                            quickStepButton(delta: 1, label: "+1")
                            quickStepButton(delta: 10, label: "+10")
                        }
                    }

                    // Virtualized list showing every level up to highest unlocked (no fixed 60 cap)
                    Section("진행 레벨 (1 ~ \(maxVisibleLevel))") {
                        ForEach(Array(stride(from: maxVisibleLevel, through: 1, by: -1)), id: \.self) { level in
                            levelRow(level: level, theme: theme)
                                .id(level)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .onAppear {
                    jumpInputText = "\(viewModel.levelNumber)"
                    DispatchQueue.main.async {
                        proxy.scrollTo(viewModel.levelNumber, anchor: .center)
                    }
                }
            }
            .navigationTitle("디버그 레벨 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
        .preferredColorScheme(theme.isDark ? .dark : .light)
    }

    private func quickStepButton(delta: Int, label: String) -> some View {
        let target = max(1, viewModel.levelNumber + delta)
        return Button(label) {
            viewModel.startLevel(target)
            dismiss()
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    private func levelRow(level: Int, theme: AppTheme) -> some View {
        let config = LevelConfig.forLevel(level)
        let isCurrent = level == viewModel.levelNumber
        let isCleared = level < viewModel.highestUnlockedLevel

        return Button {
            viewModel.startLevel(level)
            dismiss()
        } label: {
            HStack(spacing: 10) {
                Text("LV. \(level)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(isCurrent ? theme.accentColor : theme.primaryText)
                    .monospacedDigit()

                if config.isHardChallenge {
                    Text("HARD")
                        .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.heartActiveColor, in: Capsule())
                }

                if config.shape != .rectangle {
                    Label(config.shape.displayName, systemImage: config.shape.symbolName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.accentColor)
                }

                Spacer()

                Text("\(config.width)×\(config.height) · \(config.concept.displayName)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.secondaryText)

                if isCurrent {
                    Image(systemName: "play.circle.fill")
                        .foregroundStyle(theme.accentColor)
                } else if isCleared {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.16, green: 0.76, blue: 0.54))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif
