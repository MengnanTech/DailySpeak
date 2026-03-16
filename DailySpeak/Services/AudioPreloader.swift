import Foundation

/// Collects all audio items for a task and provides batch preloading.
/// IMPORTANT: IDs here MUST match exactly what the guided views use for playback.
enum AudioPreloader {

    typealias AudioItem = (id: String, text: String)

    // MARK: - Collect audio items by step type

    /// Strategy step: angles (KeyPointsGuidedView) + sequence steps (SequenceGuidedView)
    static func strategyItems(for task: SpeakingTask) -> [AudioItem] {
        guard let lesson = task.lessonContent else { return [] }
        var items: [AudioItem] = []

        // Angles — matches KeyPointsGuidedView.playbackID(for:)
        // category: "angle", text: angle.title + ". " + angle.content.joined(separator: ". ")
        for angle in lesson.strategy.angles {
            let text = angle.title + ". " + angle.content.joined(separator: ". ")
            let id = EnglishSpeechPlayer.playbackID(for: text, category: "angle")
            items.append((id: id, text: text))
        }

        // Sequence individual steps — matches SequenceGuidedView.stepPlaybackID(for:)
        // category: "seq-step", text: "\(step.phase). \(step.focus). \(step.target)"
        for step in lesson.strategy.sequence {
            let text = "\(step.phase). \(step.focus). \(step.target)"
            let id = EnglishSpeechPlayer.playbackID(for: text, category: "seq-step")
            items.append((id: id, text: text))
        }

        // Sequence combined — used in SequenceGuidedView onComplete
        // category: "sequence-all"
        let seqText = lesson.strategy.sequence
            .map { "\($0.phase). \($0.focus). \($0.target)" }
            .joined(separator: " ")
        if !seqText.isEmpty {
            let id = EnglishSpeechPlayer.playbackID(for: seqText, category: "sequence-all")
            items.append((id: id, text: seqText))
        }

        return items
    }

    /// Review step — matches ReviewGuidedView (ReviewGuideItem.playbackCategory)
    static func reviewItems(for task: SpeakingTask) -> [AudioItem] {
        guard let lesson = task.lessonContent else { return [] }
        var items: [AudioItem] = []

        // High score tips — category: "review-tip"
        for tip in lesson.strategy.highScoreTips {
            let id = EnglishSpeechPlayer.playbackID(for: tip, category: "review-tip")
            items.append((id: id, text: tip))
        }

        // Content mistakes — category: "review-content", text: "\(problem). \(fix)"
        for m in lesson.strategy.commonMistakes.content {
            let text = "\(m.problem). \(m.fix)"
            let id = EnglishSpeechPlayer.playbackID(for: text, category: "review-content")
            items.append((id: id, text: text))
        }

        // Language mistakes — category: "review-lang", text: betterExample
        for m in lesson.strategy.commonMistakes.language {
            let id = EnglishSpeechPlayer.playbackID(for: m.betterExample, category: "review-lang")
            items.append((id: id, text: m.betterExample))
        }

        return items
    }

    /// Phrases step — matches PhrasesGuidedView.phrasePlaybackID(_:)
    /// category: "phrase-guide", text: phrase.phrase
    static func phrasesItems(for task: SpeakingTask) -> [AudioItem] {
        guard let lesson = task.lessonContent else {
            return task.phrases.map { phrase in
                let id = EnglishSpeechPlayer.playbackID(for: phrase.phrase, category: "phrase-guide")
                return (id: id, text: phrase.phrase)
            }
        }
        var items: [AudioItem] = []
        for p in lesson.phrases.core {
            let id = EnglishSpeechPlayer.playbackID(for: p.phrase, category: "phrase-guide")
            items.append((id: id, text: p.phrase))
        }
        for p in lesson.phrases.extended {
            let id = EnglishSpeechPlayer.playbackID(for: p.phrase, category: "phrase-guide")
            items.append((id: id, text: p.phrase))
        }
        return items
    }

    /// Framework step — matches FrameworkGuideItem.playbackID
    static func frameworkItems(for task: SpeakingTask) -> [AudioItem] {
        guard let lesson = task.lessonContent else { return [] }
        var items: [AudioItem] = []

        // Goal — category: "fw-goal", text: framework.goal
        let goalId = EnglishSpeechPlayer.playbackID(for: lesson.framework.goal, category: "fw-goal")
        items.append((id: goalId, text: lesson.framework.goal))

        // Sections — category: "fw-section", text: section.section + moves.joined(separator: ". ")
        // FrameworkGuideItem.section: playbackID = playbackID(for: name + playableText, category: "fw-section")
        // where name = section.section, playableText = moves.joined(separator: ". ")
        for section in lesson.framework.defaultStructure {
            let movesText = section.moves.joined(separator: ". ")
            let idText = section.section + movesText
            let id = EnglishSpeechPlayer.playbackID(for: idText, category: "fw-section")
            // togglePlayback uses playableText (just moves), but playbackID uses name + playableText
            items.append((id: id, text: movesText))
        }

        // Delivery markers — category: "fw-marker", text: marker
        for marker in lesson.framework.deliveryMarkers {
            let id = EnglishSpeechPlayer.playbackID(for: marker, category: "fw-marker")
            items.append((id: id, text: marker))
        }

        return items
    }

    /// Samples step — matches SampleGuideItem.playbackID
    static func samplesItems(for task: SpeakingTask) -> [AudioItem] {
        guard let lesson = task.lessonContent else { return [] }
        var items: [AudioItem] = []

        for sample in lesson.samples {
            // Sample text — category: "sample-guide", text: sample.answer (= SampleAnswer.content)
            let sampleId = EnglishSpeechPlayer.playbackID(for: sample.answer, category: "sample-guide")
            items.append((id: sampleId, text: sample.answer))

            // Upgrade expressions — category: "sample-upgrade-guide", text: upgrade.improved
            for upgrade in sample.upgrades {
                let upgradeId = EnglishSpeechPlayer.playbackID(for: upgrade.improved, category: "sample-upgrade-guide")
                items.append((id: upgradeId, text: upgrade.improved))
            }
        }

        return items
    }

    // MARK: - Aggregate

    /// All guide audio items for the entire task.
    static func allItems(for task: SpeakingTask) -> [AudioItem] {
        var items: [AudioItem] = []
        items.append(contentsOf: strategyItems(for: task))
        items.append(contentsOf: reviewItems(for: task))
        items.append(contentsOf: phrasesItems(for: task))
        items.append(contentsOf: frameworkItems(for: task))
        items.append(contentsOf: samplesItems(for: task))

        // Focus goal
        if let goal = task.lessonContent?.topic.learningGoal, !goal.isEmpty {
            let id = EnglishSpeechPlayer.playbackID(for: goal, category: "focus-goal")
            items.append((id: id, text: goal))
        }

        return items
    }

    /// Check how many items are already cached.
    @MainActor
    static func cachedCount(for items: [AudioItem]) -> Int {
        let player = EnglishSpeechPlayer.shared
        return items.filter { player.isAudioCached(id: $0.id) }.count
    }

    /// Whether all items for a task are cached.
    @MainActor
    static func isFullyCached(for task: SpeakingTask) -> Bool {
        let items = allItems(for: task)
        return items.allSatisfy { EnglishSpeechPlayer.shared.isAudioCached(id: $0.id) }
    }

    // MARK: - Preload

    /// Preload all audio for a specific step type.
    @MainActor
    static func preloadStep(_ stepType: StepType, task: SpeakingTask) {
        let items: [AudioItem]
        switch stepType {
        case .strategy: items = strategyItems(for: task)
        case .review:   items = reviewItems(for: task)
        case .phrases:  items = phrasesItems(for: task)
        case .framework: items = frameworkItems(for: task)
        case .samples:  items = samplesItems(for: task)
        case .vocabulary, .practice: return // No guided audio
        }
        guard !items.isEmpty else { return }
        Task {
            await EnglishSpeechPlayer.shared.preloadBatch(items)
        }
    }

    /// Preload all audio for the entire task.
    @MainActor
    static func preloadAll(for task: SpeakingTask) {
        let items = allItems(for: task)
        guard !items.isEmpty else { return }
        Task {
            await EnglishSpeechPlayer.shared.preloadBatch(items)
        }
    }

}
