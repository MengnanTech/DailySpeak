import Foundation

struct LessonPreviewContent {
    let questionID: Int
    let topic: PreviewTopic
    let strategy: PreviewAnswerStrategy
    let framework: PreviewFramework
    let practice: PreviewPractice

    struct PreviewTopic {
        let stageNumber: Int
        let stageLabel: String
        let titleCN: String
        let promptEN: String
        let category: String
        let target: String
        let recommendedLength: String
        let learningGoal: String?
    }

    struct PreviewAnswerStrategy {
        let angles: [Angle]
        let sequence: [SequenceStep]
        let contentRatio: [RatioItem]
        let highScoreTips: [String]
        let contentMistakes: [Mistake]
        let languageMistakes: [LanguageMistake]

        struct Angle {
            let title: String
            let content: [String]
        }

        struct SequenceStep {
            let phase: String
            let focus: String
            let target: String
        }

        struct RatioItem {
            let label: String
            let value: String
        }

        struct Mistake {
            let problem: String
            let whyItHurts: String
            let fix: String
        }

        struct LanguageMistake {
            let problem: String
            let wrongExample: String
            let betterExample: String
            let reason: String
        }
    }

    struct PreviewFramework {
        let goal: String
        let defaultStructure: [StructureSection]
        let deliveryMarkers: [String]

        struct StructureSection {
            let section: String
            let moves: [String]
        }
    }

    struct PreviewPractice {
        let task: String
        let targetLength: String
        let checklist: [String]
        let selfPrompts: [String]
    }
}

private struct RawJSONLessonPreview: Decodable {
    let id: String
    let topic: RawTopic
    let strategy: RawAnswerStrategy
    let framework: RawResponseFramework
    let samples: [RawSampleAnswer]
    let vocabulary: RawVocabularyGroups
    let phrases: RawPhraseGroups
    let practice: RawPractice

    struct RawTopic: Decodable {
        let stage: Int
        let stageLabel: String
        let titleCn: String
        let promptEn: String
        let category: String
        let target: String
        let recommendedLength: String
        let learningGoal: String?
    }

    struct RawAnswerStrategy: Decodable {
        let angles: [RawAngle]
        let sequence: [RawSequenceStep]
        let contentRatio: RawContentRatio
        let highScoreTips: [String]
        let commonMistakes: RawCommonMistakes

        struct RawAngle: Decodable {
            let title: String
            let content: [String]
        }

        struct RawSequenceStep: Decodable {
            let phase: String
            let focus: String
            let target: String
        }

        struct RawContentRatio: Decodable {
            let traitsAndContext: String
            let story: String
            let reflection: String
        }

        struct RawCommonMistakes: Decodable {
            let content: [RawMistake]
            let language: [RawLanguageMistake]
        }

        struct RawMistake: Decodable {
            let problem: String
            let whyItHurts: String
            let fix: String
        }

        struct RawLanguageMistake: Decodable {
            let problem: String
            let wrongExample: String
            let betterExample: String
            let reason: String
        }
    }

    struct RawResponseFramework: Decodable {
        let goal: String
        let defaultStructure: [RawStructureSection]
        let deliveryMarkers: [String]

        struct RawStructureSection: Decodable {
            let section: String
            let moves: [String]
        }

    }

    struct RawSampleAnswer: Decodable {
        let band: Int
        let answer: String
        let highlights: [String]
        let bandGuide: RawBandGuide
        let upgrades: [RawUpgrade]

        struct RawBandGuide: Decodable {
            let band: Int
            let focus: String
            let opening: [String]
            let body: [String]
            let closing: [String]
        }

        struct RawUpgrade: Decodable {
            let original: String
            let improved: String
            let why: String
            let note: String
        }
    }

    struct RawVocabularyGroups: Decodable {
        let core: [RawCoreVocabularyItem]
        let extended: [RawExtendedVocabularyItem]
    }

    struct RawCoreVocabularyItem: Decodable {
        let item: String
        let pos: String
        let meaningZh: String
        let band: Int
        let example: String
    }

    struct RawExtendedVocabularyItem: Decodable {
        let item: String
        let pos: String
        let meaningZh: String
        let note: String
    }

    struct RawPhraseGroups: Decodable {
        let core: [RawCorePhraseItem]
        let extended: [RawExtendedPhraseItem]
    }

    struct RawCorePhraseItem: Decodable {
        let phrase: String
        let meaningZh: String
        let band: Int
    }

    struct RawExtendedPhraseItem: Decodable {
        let phrase: String
        let meaningZh: String
        let note: String
    }

    struct RawPractice: Decodable {
        let task: String
        let targetLength: String
        let checklist: [String]
        let selfPrompts: [String]
    }
}

enum PreviewTaskFactory {
    static func q01DescribePersonTask(id: Int) -> SpeakingTask {
        guard let preview = loadQ01() else {
            return .placeholder(
                id: id,
                title: "描述一个人",
                englishTitle: "Describe a Person",
                prompt: "Describe a person you know well."
            )
        }

        return preview.asSpeakingTask(id: id)
    }

    private static func loadQ01() -> RawJSONLessonPreview? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let candidates: [URL?] = [
            Bundle.main.url(forResource: "q01_describe_a_person", withExtension: "json", subdirectory: "Resources"),
            Bundle.main.url(forResource: "q01_describe_a_person", withExtension: "json")
        ]

        for url in candidates.compactMap({ $0 }) {
            guard let data = try? Data(contentsOf: url) else { continue }
            if let preview = try? decoder.decode(RawJSONLessonPreview.self, from: data) {
                return preview
            }
        }

        return nil
    }
}

private extension RawJSONLessonPreview {
    func asSpeakingTask(id: Int) -> SpeakingTask {
        let previewContent = asPreviewContent()

        return SpeakingTask(
            id: id,
            title: topic.titleCn,
            englishTitle: "Describe a Person",
            prompt: topic.promptEn,
            questionType: "JSON Preview",
            suggestedTime: practice.targetLength,
            difficulty: "\(topic.stageLabel) · Preview",
            passCriteria: practice.checklist + ["Target length: \(practice.targetLength)"],
            steps: [
                LearningStep(id: 0, type: .strategy),
                LearningStep(id: 1, type: .vocabulary),
                LearningStep(id: 2, type: .phrases),
                LearningStep(id: 3, type: .framework),
                LearningStep(id: 4, type: .samples),
                LearningStep(id: 5, type: .practice)
            ],
            tips: Array(strategy.highScoreTips.prefix(4)),
            vocabulary: adaptedVocabulary(),
            phrases: adaptedPhrases(),
            frameworkSentences: adaptedFrameworkSentences(),
            sampleAnswers: adaptedSampleAnswers(),
            upgradeExpressions: samples.flatMap(\.upgrades).map { ($0.original, $0.improved) },
            previewContent: previewContent
        )
    }

    func asPreviewContent() -> LessonPreviewContent {
        LessonPreviewContent(
            questionID: questionNumber(),
            topic: .init(
                stageNumber: topic.stage,
                stageLabel: topic.stageLabel,
                titleCN: topic.titleCn,
                promptEN: topic.promptEn,
                category: topic.category,
                target: topic.target,
                recommendedLength: topic.recommendedLength,
                learningGoal: topic.learningGoal
            ),
            strategy: .init(
                angles: strategy.angles.map {
                    .init(title: $0.title, content: $0.content)
                },
                sequence: strategy.sequence.map {
                    .init(phase: $0.phase, focus: $0.focus, target: $0.target)
                },
                contentRatio: [
                    .init(label: "Traits & Context", value: strategy.contentRatio.traitsAndContext),
                    .init(label: "Story", value: strategy.contentRatio.story),
                    .init(label: "Reflection", value: strategy.contentRatio.reflection)
                ],
                highScoreTips: strategy.highScoreTips,
                contentMistakes: strategy.commonMistakes.content.map {
                    .init(problem: $0.problem, whyItHurts: $0.whyItHurts, fix: $0.fix)
                },
                languageMistakes: strategy.commonMistakes.language.map {
                    .init(problem: $0.problem, wrongExample: $0.wrongExample, betterExample: $0.betterExample, reason: $0.reason)
                }
            ),
            framework: .init(
                goal: framework.goal,
                defaultStructure: framework.defaultStructure.map {
                    .init(section: $0.section, moves: $0.moves)
                },
                deliveryMarkers: framework.deliveryMarkers
            ),
            practice: .init(
                task: practice.task,
                targetLength: practice.targetLength,
                checklist: practice.checklist,
                selfPrompts: practice.selfPrompts
            )
        )
    }

    func adaptedVocabulary() -> [VocabItem] {
        let core = vocabulary.core.map {
            VocabItem(
                word: $0.item,
                phonetic: "",
                meaning: $0.meaningZh,
                englishMeaning: "",
                example: $0.example,
                exampleTranslation: "",
                band: .core,
                providedPartOfSpeech: $0.pos,
                sourceBand: "Band \($0.band)"
            )
        }

        let extended = vocabulary.extended.enumerated().map { index, item in
            VocabItem(
                word: item.item,
                phonetic: "",
                meaning: item.meaningZh,
                englishMeaning: "",
                example: "",
                exampleTranslation: "",
                band: index < 3 ? .upgrade : .advanced,
                providedPartOfSpeech: item.pos,
                nativeNote: item.note
            )
        }

        return core + extended
    }

    func adaptedPhrases() -> [PhraseItem] {
        let core = phrases.core.map {
            PhraseItem(
                phrase: $0.phrase,
                example: "",
                meaning: $0.meaningZh,
                sourceBand: "Band \($0.band)"
            )
        }

        let extended = phrases.extended.map {
            PhraseItem(
                phrase: $0.phrase,
                example: "",
                meaning: $0.meaningZh,
                nativeNote: $0.note
            )
        }

        return core + extended
    }

    func adaptedFrameworkSentences() -> [String] {
        let sortedGuides = samples
            .map(\.bandGuide)
            .sorted { $0.band < $1.band }
        guard let baseGuide = sortedGuides.first else {
            return [
                "The person I'd like to talk about is ...",
                "I've known this person for ...",
                "In terms of personality, this person is ...",
                "A good example is when ...",
                "That's why this person matters to me."
            ]
        }

        return [
            baseGuide.opening.first ?? "The person I'd like to talk about is ...",
            baseGuide.opening.dropFirst().first ?? "I've known this person for ...",
            baseGuide.body.first ?? "In terms of personality, this person is ...",
            baseGuide.body.dropFirst().first ?? "A good example is when ...",
            baseGuide.closing.first ?? "That's why this person matters to me."
        ]
    }

    func adaptedSampleAnswers() -> [SampleAnswer] {
        samples.map {
            SampleAnswer(
                band: "Band \($0.band)",
                wordCount: wordCount(in: $0.answer),
                content: $0.answer,
                nativeFeatures: $0.highlights,
                bandGuide: .init(
                    band: $0.bandGuide.band,
                    focus: $0.bandGuide.focus,
                    opening: $0.bandGuide.opening,
                    body: $0.bandGuide.body,
                    closing: $0.bandGuide.closing
                ),
                upgrades: $0.upgrades.map {
                    .init(
                        original: $0.original,
                        improved: $0.improved,
                        why: $0.why,
                        note: $0.note
                    )
                }
            )
        }
    }

    private func questionNumber() -> Int {
        Int(id.replacingOccurrences(of: "q", with: "")) ?? 1
    }

    private func wordCount(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
