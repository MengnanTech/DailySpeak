import Foundation

struct LessonManifest: Decodable {
    let stageId: Int
    let stageLabel: String
    let lessons: [LessonDescriptor]

    struct LessonDescriptor: Decodable {
        let id: Int
        let stage: Int
        let titleCn: String
        let titleEn: String
        let prompt: String
        let filename: String
        let structuredContent: Bool
    }
}

struct LessonContent: Decodable {
    let id: String
    let topic: Topic
    let strategy: Strategy
    let vocabulary: VocabularyGroups
    let phrases: PhraseGroups
    let framework: Framework
    let samples: [Sample]
    let practice: Practice

    struct Topic: Decodable {
        let stage: Int
        let stageLabel: String
        let titleCn: String
        let promptEn: String
        let learningGoal: String?
        let category: String
        let target: String
        let recommendedLength: String
    }

    struct Strategy: Decodable {
        let angles: [Angle]
        let sequence: [SequenceStep]
        let contentRatio: [ContentRatioItem]
        let highScoreTips: [String]
        let commonMistakes: CommonMistakes

        struct Angle: Decodable {
            let title: String
            let content: [String]
        }

        struct SequenceStep: Decodable {
            let phase: String
            let focus: String
            let target: String
        }

        struct ContentRatioItem: Decodable {
            let label: String
            let value: String
        }

        struct CommonMistakes: Decodable {
            let content: [ContentMistake]
            let language: [LanguageMistake]
        }

        struct ContentMistake: Decodable {
            let problem: String
            let whyItHurts: String
            let fix: String
        }

        struct LanguageMistake: Decodable {
            let problem: String
            let wrongExample: String
            let betterExample: String
            let reason: String
        }
    }

    struct VocabularyGroups: Decodable {
        let core: [CoreVocabularyItem]
        let extended: [ExtendedVocabularyItem]
    }

    struct CoreVocabularyItem: Decodable {
        let item: String
        let pos: String
        let meaningZh: String
        let band: Int
        let example: String
    }

    struct ExtendedVocabularyItem: Decodable {
        let item: String
        let pos: String
        let meaningZh: String
        let note: String
    }

    struct PhraseGroups: Decodable {
        let core: [CorePhraseItem]
        let extended: [ExtendedPhraseItem]
    }

    struct CorePhraseItem: Decodable {
        let phrase: String
        let meaningZh: String
        let band: Int
        let example: String?
    }

    struct ExtendedPhraseItem: Decodable {
        let phrase: String
        let meaningZh: String
        let note: String
        let example: String?
    }

    struct Framework: Decodable {
        let goal: String
        let defaultStructure: [StructureSection]
        let deliveryMarkers: [String]

        struct StructureSection: Decodable {
            let section: String
            let moves: [String]
        }
    }

    struct Sample: Decodable {
        let band: Int
        let answer: String
        let highlights: [String]
        let bandGuide: BandGuide
        let upgrades: [Upgrade]

        struct BandGuide: Decodable {
            let band: Int
            let focus: String
            let opening: [String]
            let body: [String]
            let closing: [String]
        }

        struct Upgrade: Decodable {
            let original: String
            let improved: String
            let why: String
            let note: String
        }
    }

    struct Practice: Decodable {
        let task: String
        let targetLength: String
        let checklist: [String]
        let selfPrompts: [String]
    }
}

protocol LessonContentSource {
    func loadManifest(named name: String) throws -> LessonManifest
    func loadLessonContent(filename: String) throws -> LessonContent
}

struct BundleLessonContentSource: LessonContentSource {
    private let bundle: Bundle
    private let decoder: JSONDecoder

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func loadManifest(named name: String) throws -> LessonManifest {
        let data = try loadData(name: name, withExtension: "json")
        return try decoder.decode(LessonManifest.self, from: data)
    }

    func loadLessonContent(filename: String) throws -> LessonContent {
        let fileURL = URL(fileURLWithPath: filename)
        let name = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension.isEmpty ? "json" : fileURL.pathExtension
        let data = try loadData(name: name, withExtension: ext)
        return try decoder.decode(LessonContent.self, from: data)
    }

    private func loadData(name: String, withExtension ext: String) throws -> Data {
        let candidates: [URL?] = [
            bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources"),
            bundle.url(forResource: name, withExtension: ext)
        ]

        for url in candidates.compactMap({ $0 }) {
            if let data = try? Data(contentsOf: url) {
                return data
            }
        }

        throw NSError(domain: "LessonRepository", code: 404, userInfo: [
            NSLocalizedDescriptionKey: "Missing bundled resource: \(name).\(ext)"
        ])
    }
}

enum LessonRepository {
    static func loadTasks(forStage stage: Int, source: any LessonContentSource = BundleLessonContentSource()) -> [SpeakingTask] {
        guard let manifest = try? source.loadManifest(named: "stage\(stage)_manifest") else {
            return []
        }

        let descriptors = manifest.lessons

        return descriptors.map { descriptor in
            guard descriptor.structuredContent,
                  let lesson = try? source.loadLessonContent(filename: descriptor.filename)
            else {
                return .placeholder(
                    id: descriptor.id,
                    title: descriptor.titleCn,
                    englishTitle: descriptor.titleEn,
                    prompt: descriptor.prompt
                )
            }

            return lesson.asSpeakingTask(
                id: descriptor.id,
                englishTitle: descriptor.titleEn
            )
        }
    }
}

private extension LessonContent {
    func asSpeakingTask(id: Int, englishTitle: String) -> SpeakingTask {
        SpeakingTask(
            id: id,
            title: topic.titleCn,
            englishTitle: englishTitle,
            prompt: topic.promptEn,
            questionType: topic.target,
            suggestedTime: practice.targetLength,
            difficulty: "\(topic.stageLabel) · Structured",
            passCriteria: practice.checklist + ["Target length: \(practice.targetLength)"],
            steps: [
                LearningStep(id: 0, type: .strategy),
                LearningStep(id: 1, type: .review),
                LearningStep(id: 2, type: .vocabulary),
                LearningStep(id: 3, type: .phrases),
                LearningStep(id: 4, type: .framework),
                LearningStep(id: 5, type: .samples),
                LearningStep(id: 6, type: .practice)
            ],
            tips: Array(strategy.highScoreTips.prefix(4)),
            vocabulary: adaptedVocabulary(),
            phrases: adaptedPhrases(),
            frameworkSentences: adaptedFrameworkSentences(),
            sampleAnswers: adaptedSampleAnswers(),
            upgradeExpressions: samples.flatMap(\.upgrades).map { ($0.original, $0.improved) },
            lessonContent: self
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
                example: $0.example ?? "",
                meaning: $0.meaningZh,
                sourceBand: "Band \($0.band)"
            )
        }

        let extended = phrases.extended.map {
            PhraseItem(
                phrase: $0.phrase,
                example: $0.example ?? "",
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
                "The topic I'd like to talk about is ...",
                "It became important to me when ...",
                "What stands out is ...",
                "A good example is when ...",
                "Overall, that's why it matters to me."
            ]
        }

        return [
            baseGuide.opening.first ?? "The topic I'd like to talk about is ...",
            baseGuide.opening.dropFirst().first ?? "It became important to me when ...",
            baseGuide.body.first ?? "What stands out is ...",
            baseGuide.body.dropFirst().first ?? "A good example is when ...",
            baseGuide.closing.first ?? "Overall, that's why it matters to me."
        ]
    }

    func adaptedSampleAnswers() -> [SampleAnswer] {
        samples.map {
            SampleAnswer(
                band: bandLabel(for: $0.band),
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

    func bandLabel(for band: Int) -> String {
        switch band {
        case 6: return "Band 6.5–7.0"
        case 7: return "Band 7.0–7.5"
        case 8: return "Band 8.0+"
        default: return "Band \(band)"
        }
    }

    func wordCount(in answer: String) -> Int {
        answer
            .split { $0.isWhitespace || $0.isNewline }
            .count
    }
}
