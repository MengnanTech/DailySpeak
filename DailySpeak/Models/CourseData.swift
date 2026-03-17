import Foundation
import SwiftUI

// MARK: - Step Type
enum StepType: Int, CaseIterable, Codable {
    case strategy   = 0
    case vocabulary = 1
    case phrases    = 2
    case framework  = 3
    case samples    = 4
    case practice   = 5
    case review     = 6

    var title: String {
        switch self {
        case .strategy:   String(localized: "Answer Strategy")
        case .review:     String(localized: "Score Check")
        case .vocabulary:  String(localized: "Key Vocabulary")
        case .phrases:     String(localized: "Useful Phrases")
        case .framework:   String(localized: "Expression Framework")
        case .samples:     String(localized: "Sample Answers")
        case .practice:    String(localized: "Speaking Practice")
        }
    }

    var subtitle: String {
        switch self {
        case .strategy:   "Build answer structure and organize expression"
        case .review:     "Check scoring points, content gaps and language"
        case .vocabulary:  "Master key words and pronunciation"
        case .phrases:     "Learn native expressions and examples"
        case .framework:   "Master templates and upgraded expressions"
        case .samples:     "Three-level model answers"
        case .practice:    "Real practice — speak English out loud"
        }
    }

    var icon: String {
        switch self {
        case .strategy:   "lightbulb.fill"
        case .review:     "checklist"
        case .vocabulary:  "character.book.closed.fill"
        case .phrases:     "text.quote"
        case .framework:   "rectangle.3.group.fill"
        case .samples:     "doc.richtext.fill"
        case .practice:    "mic.fill"
        }
    }

    var color: Color {
        switch self {
        case .strategy:   Color(hex: "F59E0B")
        case .review:     Color(hex: "F97316")
        case .vocabulary:  Color(hex: "4A90D9")
        case .phrases:     Color(hex: "10B981")
        case .framework:   Color(hex: "8B5CF6")
        case .samples:     Color(hex: "EC4899")
        case .practice:    Color(hex: "EF4444")
        }
    }
}

// MARK: - Learning Step
struct LearningStep: Identifiable {
    let id: Int
    let type: StepType
    var title: String { type.title }
    var subtitle: String { type.subtitle }
    var icon: String { type.icon }

    static let allSteps: [LearningStep] = [
        LearningStep(id: StepType.vocabulary.rawValue, type: .vocabulary),
        LearningStep(id: StepType.phrases.rawValue, type: .phrases),
        LearningStep(id: StepType.samples.rawValue, type: .samples),
        LearningStep(id: StepType.framework.rawValue, type: .framework),
        LearningStep(id: StepType.practice.rawValue, type: .practice),
    ]
}

// MARK: - Vocabulary Item
struct VocabItem: Identifiable {
    let id = UUID()
    let word: String
    let phonetic: String
    let meaning: String
    let englishMeaning: String
    let example: String
    let exampleTranslation: String
    let band: BandLevel
    let providedPartOfSpeech: String?
    let sourceBand: String?
    let nativeNote: String?

    init(
        word: String,
        phonetic: String,
        meaning: String,
        englishMeaning: String,
        example: String,
        exampleTranslation: String,
        band: BandLevel,
        providedPartOfSpeech: String? = nil,
        sourceBand: String? = nil,
        nativeNote: String? = nil
    ) {
        self.word = word
        self.phonetic = phonetic
        self.meaning = meaning
        self.englishMeaning = englishMeaning
        self.example = example
        self.exampleTranslation = exampleTranslation
        self.band = band
        self.providedPartOfSpeech = providedPartOfSpeech
        self.sourceBand = sourceBand
        self.nativeNote = nativeNote
    }

    enum BandLevel: String, CaseIterable {
        case core     = "Core"
        case upgrade  = "Upgrade"
        case advanced = "Advanced"

        var bandLabel: String {
            switch self {
            case .core:     "Band 6"
            case .upgrade:  "Band 7"
            case .advanced: "Band 8+"
            }
        }

        var color: Color {
            switch self {
            case .core:     Color(hex: "4A90D9")
            case .upgrade:  Color(hex: "F59E0B")
            case .advanced: Color(hex: "EF4444")
            }
        }
    }

    var partOfSpeech: String {
        if let providedPartOfSpeech, !providedPartOfSpeech.isEmpty {
            return providedPartOfSpeech
        }
        switch word {
        case "practical", "durable", "convenient", "lightweight", "reliable",
             "affordable", "time-saving", "user-friendly", "portable",
             "functional", "versatile", "long-lasting", "cost-effective",
             "irreplaceable", "indispensable":
            return "adj."
        case "sentimental value", "subtle impact", "mindful habit":
            return "n. phr."
        case "stay hydrated", "serve a specific purpose", "strike a balance":
            return "v. phr."
        case "environmentally friendly", "aesthetically pleasing":
            return "adj. phr."
        default:
            return "expr."
        }
    }
}

// MARK: - Phrase Item
struct PhraseItem: Identifiable {
    let id = UUID()
    let phrase: String
    let example: String
    let meaning: String?
    let sourceBand: String?
    let nativeNote: String?

    init(
        phrase: String,
        example: String,
        meaning: String? = nil,
        sourceBand: String? = nil,
        nativeNote: String? = nil
    ) {
        self.phrase = phrase
        self.example = example
        self.meaning = meaning
        self.sourceBand = sourceBand
        self.nativeNote = nativeNote
    }
}

// MARK: - Sample Answer
struct SampleAnswer: Identifiable {
    struct BandGuide {
        let band: Int
        let focus: String
        let opening: [String]
        let body: [String]
        let closing: [String]
    }

    struct Upgrade {
        let original: String
        let improved: String
        let why: String
        let note: String
    }

    let id = UUID()
    let band: String
    let wordCount: Int
    let content: String
    let nativeFeatures: [String]
    let bandGuide: BandGuide?
    let upgrades: [Upgrade]

    init(
        band: String,
        wordCount: Int,
        content: String,
        nativeFeatures: [String] = [],
        bandGuide: BandGuide? = nil,
        upgrades: [Upgrade] = []
    ) {
        self.band = band
        self.wordCount = wordCount
        self.content = content
        self.nativeFeatures = nativeFeatures
        self.bandGuide = bandGuide
        self.upgrades = upgrades
    }
}

// MARK: - Speaking Task
struct SpeakingTask: Identifiable {
    let id: Int
    let title: String
    let englishTitle: String
    let prompt: String
    let questionType: String
    let suggestedTime: String
    let difficulty: String
    let passCriteria: [String]
    let steps: [LearningStep]
    let tips: [String]
    let vocabulary: [VocabItem]
    let phrases: [PhraseItem]
    let frameworkSentences: [String]
    let sampleAnswers: [SampleAnswer]
    let upgradeExpressions: [(original: String, upgraded: String)]
    let lessonContent: LessonContent?

    init(
        id: Int,
        title: String,
        englishTitle: String,
        prompt: String,
        questionType: String,
        suggestedTime: String,
        difficulty: String,
        passCriteria: [String],
        steps: [LearningStep],
        tips: [String],
        vocabulary: [VocabItem],
        phrases: [PhraseItem],
        frameworkSentences: [String],
        sampleAnswers: [SampleAnswer],
        upgradeExpressions: [(original: String, upgraded: String)],
        lessonContent: LessonContent? = nil
    ) {
        self.id = id
        self.title = title
        self.englishTitle = englishTitle
        self.prompt = prompt
        self.questionType = questionType
        self.suggestedTime = suggestedTime
        self.difficulty = difficulty
        self.passCriteria = passCriteria
        self.steps = steps
        self.tips = tips
        self.vocabulary = vocabulary
        self.phrases = phrases
        self.frameworkSentences = frameworkSentences
        self.sampleAnswers = sampleAnswers
        self.upgradeExpressions = upgradeExpressions
        self.lessonContent = lessonContent
    }

    static func placeholder(id: Int, title: String, englishTitle: String, prompt: String) -> SpeakingTask {
        SpeakingTask(
            id: id,
            title: title,
            englishTitle: englishTitle,
            prompt: prompt,
            questionType: "Task #\(id)",
            suggestedTime: String(localized: "Prepare 1 min; Answer 1-2 min"),
            difficulty: "L\(id) → L\(id + 1)",
            passCriteria: [
                String(localized: "Speak continuously for 90 seconds without notes"),
                String(localized: "Use at least 6 keywords"),
                String(localized: "Give at least 1 specific story"),
                String(localized: "No more than 3 long pauses")
            ],
            steps: LearningStep.allSteps,
            tips: [
                String(localized: "Identify your subject — choose something you truly know"),
                String(localized: "Focus on appearance, function, and usage scenarios"),
                String(localized: "Add personal experiences to make your answer vivid"),
                String(localized: "Use chronological or logical order to organize")
            ],
            vocabulary: VocabItem.placeholders,
            phrases: PhraseItem.placeholders,
            frameworkSentences: [
                "The ... I'd like to describe is ...",
                "I got/found it ... ago, and I started ...",
                "I use/do it mainly for ..., especially when ...",
                "For example, one day ... and it really ...",
                "So even though it seems ..., it means a lot to me because ..."
            ],
            sampleAnswers: SampleAnswer.placeholders,
            upgradeExpressions: [
                ("I use it every day.", "I rely on it on a daily basis."),
                ("It is very useful.", "It serves a highly practical purpose."),
                ("I like it because it is simple.", "I prefer it because of its minimalist design."),
                ("It changed my habit.", "It gradually reshaped one of my daily habits."),
                ("It is important to me.", "It matters to me more than I expected.")
            ]
        )
    }
}

// MARK: - Stage
struct Stage: Identifiable {
    let id: Int
    let title: String
    let chineseTitle: String
    let description: String
    let tasks: [SpeakingTask]

    var theme: StageTheme { StageTheme.all[id - 1] }
    var taskCount: Int { tasks.count }
}

// MARK: - Placeholder Data
extension VocabItem {
    static let placeholders: [VocabItem] = [
        VocabItem(
            word: "practical",
            phonetic: "/ˈpræktɪkəl/",
            meaning: "实用的",
            englishMeaning: "useful in real situations",
            example: "It's practical for everyday use.",
            exampleTranslation: "它非常适合日常使用。",
            band: .core
        ),
        VocabItem(
            word: "durable",
            phonetic: "/ˈdjʊərəbl/",
            meaning: "耐用的",
            englishMeaning: "able to last a long time",
            example: "The bottle is durable and hard to break.",
            exampleTranslation: "这个水瓶很耐用，不容易坏。",
            band: .core
        ),
        VocabItem(
            word: "convenient",
            phonetic: "/kənˈviːniənt/",
            meaning: "方便的",
            englishMeaning: "easy to use or access",
            example: "It's convenient when I'm in a rush.",
            exampleTranslation: "赶时间的时候它很方便。",
            band: .core
        ),
        VocabItem(
            word: "lightweight",
            phonetic: "/ˈlaɪtweɪt/",
            meaning: "轻便的",
            englishMeaning: "not heavy and easy to carry",
            example: "It's lightweight, so I carry it everywhere.",
            exampleTranslation: "它很轻，所以我到处都带着。",
            band: .core
        ),
        VocabItem(
            word: "reliable",
            phonetic: "/rɪˈlaɪəbl/",
            meaning: "可靠的",
            englishMeaning: "can be trusted to work well",
            example: "It's reliable even after years of use.",
            exampleTranslation: "用了很多年它依然可靠。",
            band: .core
        ),
        VocabItem(
            word: "affordable",
            phonetic: "/əˈfɔːrdəbl/",
            meaning: "价格实惠的",
            englishMeaning: "not expensive; reasonably priced",
            example: "It's affordable for most students.",
            exampleTranslation: "对大多数学生来说价格都能接受。",
            band: .core
        ),
        VocabItem(
            word: "time-saving",
            phonetic: "/ˈtaɪm ˌseɪvɪŋ/",
            meaning: "省时的",
            englishMeaning: "helping you save time",
            example: "This app is time-saving for my study plan.",
            exampleTranslation: "这个应用让我的学习计划更省时间。",
            band: .core
        ),
        VocabItem(
            word: "user-friendly",
            phonetic: "/ˌjuːzər ˈfrendli/",
            meaning: "易用的",
            englishMeaning: "easy for people to use",
            example: "The interface is simple and user-friendly.",
            exampleTranslation: "这个界面简洁且很容易上手。",
            band: .core
        ),
        VocabItem(
            word: "sentimental value",
            phonetic: "/ˌsentɪˈmentl ˈvæljuː/",
            meaning: "情感价值",
            englishMeaning: "emotional importance",
            example: "It has sentimental value because it was a gift.",
            exampleTranslation: "因为是礼物，所以它有情感价值。",
            band: .upgrade
        ),
        VocabItem(
            word: "stay hydrated",
            phonetic: "/steɪ haɪˈdreɪtɪd/",
            meaning: "保持水分",
            englishMeaning: "drink enough water to stay healthy",
            example: "I use it to stay hydrated during work.",
            exampleTranslation: "我在工作时用它来保持补水。",
            band: .upgrade
        ),
        VocabItem(
            word: "portable",
            phonetic: "/ˈpɔːrtəbl/",
            meaning: "便携的",
            englishMeaning: "easy to carry around",
            example: "It's portable enough for daily commuting.",
            exampleTranslation: "它足够便携，适合每天通勤携带。",
            band: .upgrade
        ),
        VocabItem(
            word: "functional",
            phonetic: "/ˈfʌŋkʃənl/",
            meaning: "功能性的",
            englishMeaning: "designed to work well for a purpose",
            example: "It's not fancy, but very functional.",
            exampleTranslation: "它不花哨，但很实用。",
            band: .upgrade
        ),
        VocabItem(
            word: "versatile",
            phonetic: "/ˈvɜːrsətl/",
            meaning: "多功能的",
            englishMeaning: "able to be used in many ways",
            example: "It's versatile for office, gym, and travel.",
            exampleTranslation: "它在办公室、健身和旅行中都很好用。",
            band: .upgrade
        ),
        VocabItem(
            word: "long-lasting",
            phonetic: "/ˌlɔːŋ ˈlæstɪŋ/",
            meaning: "持久耐用的",
            englishMeaning: "continuing for a long period of time",
            example: "It's long-lasting and worth the money.",
            exampleTranslation: "它很耐用，物有所值。",
            band: .upgrade
        ),
        VocabItem(
            word: "cost-effective",
            phonetic: "/ˌkɔːst ɪˈfektɪv/",
            meaning: "性价比高的",
            englishMeaning: "good value compared with cost",
            example: "It's a cost-effective choice for students.",
            exampleTranslation: "对学生来说这是性价比很高的选择。",
            band: .upgrade
        ),
        VocabItem(
            word: "environmentally friendly",
            phonetic: "/ɪnˌvaɪrənˈmentəli ˈfrendli/",
            meaning: "环保的",
            englishMeaning: "causing less harm to the environment",
            example: "Using it is more environmentally friendly.",
            exampleTranslation: "使用它会更加环保。",
            band: .upgrade
        ),
        VocabItem(
            word: "irreplaceable",
            phonetic: "/ˌɪrɪˈpleɪsəbl/",
            meaning: "不可替代的",
            englishMeaning: "too important to be replaced",
            example: "It feels irreplaceable in my routine.",
            exampleTranslation: "在我的日常中它几乎不可替代。",
            band: .advanced
        ),
        VocabItem(
            word: "subtle impact",
            phonetic: "/ˈsʌtl ˈɪmpækt/",
            meaning: "微妙影响",
            englishMeaning: "a small but meaningful effect",
            example: "It has a subtle impact on my lifestyle.",
            exampleTranslation: "它对我的生活方式有微妙但真实的影响。",
            band: .advanced
        ),
        VocabItem(
            word: "mindful habit",
            phonetic: "/ˈmaɪndfʊl ˈhæbɪt/",
            meaning: "有意识的习惯",
            englishMeaning: "a habit done with awareness",
            example: "Drinking water became a mindful habit.",
            exampleTranslation: "喝水逐渐成了一个有意识的习惯。",
            band: .advanced
        ),
        VocabItem(
            word: "indispensable",
            phonetic: "/ˌɪndɪˈspensəbl/",
            meaning: "必不可少的",
            englishMeaning: "absolutely necessary",
            example: "It has become indispensable in my bag.",
            exampleTranslation: "它已成为我包里不可或缺的东西。",
            band: .advanced
        ),
        VocabItem(
            word: "aesthetically pleasing",
            phonetic: "/iːsˈθetɪkli ˈpliːzɪŋ/",
            meaning: "审美上令人愉悦的",
            englishMeaning: "beautiful or attractive in appearance",
            example: "Its design is aesthetically pleasing.",
            exampleTranslation: "它的设计在视觉上很舒服。",
            band: .advanced
        ),
        VocabItem(
            word: "serve a specific purpose",
            phonetic: "/sɜːrv ə spəˈsɪfɪk ˈpɜːrpəs/",
            meaning: "服务于明确用途",
            englishMeaning: "to be used for a clear function",
            example: "Every feature serves a specific purpose.",
            exampleTranslation: "每个功能都有明确用途。",
            band: .advanced
        ),
        VocabItem(
            word: "strike a balance",
            phonetic: "/straɪk ə ˈbæləns/",
            meaning: "取得平衡",
            englishMeaning: "to manage two sides well",
            example: "It helps me strike a balance between work and health.",
            exampleTranslation: "它帮助我在工作和健康之间取得平衡。",
            band: .advanced
        ),
    ]
}

extension PhraseItem {
    static let placeholders: [PhraseItem] = [
        PhraseItem(phrase: "come in handy", example: "It comes in handy when I have long meetings."),
        PhraseItem(phrase: "part of my routine", example: "It has become part of my daily routine."),
        PhraseItem(phrase: "keep me on track", example: "It keeps me on track with my water intake."),
        PhraseItem(phrase: "not fancy, but functional", example: "It's not fancy, but highly functional."),
        PhraseItem(phrase: "on the go", example: "I carry it with me when I'm on the go."),
        PhraseItem(phrase: "make a noticeable difference", example: "This small habit makes a noticeable difference."),
        PhraseItem(phrase: "attached to", example: "I've grown attached to it over time."),
        PhraseItem(phrase: "without fail", example: "I refill it twice a day without fail."),
        PhraseItem(phrase: "serve as a reminder", example: "It serves as a reminder to take care of myself."),
        PhraseItem(phrase: "hard to replace", example: "Even if it's cheap, it's hard to replace for me."),
    ]
}

extension SampleAnswer {
    static let placeholders: [SampleAnswer] = [
        SampleAnswer(
            band: "Band 6.0–6.5",
            wordCount: 135,
            content: "The object I want to describe is my stainless-steel water bottle. I bought it about two years ago from a supermarket near my office. It is black, simple, and easy to carry. I use it every day at work and at the gym. Usually, I refill it two or three times a day.\n\nWhat I like most is that it keeps water cold for a long time, so I drink more water than before. One time, I was very busy and almost forgot to drink anything for hours. When I saw the bottle on my desk, I remembered to take a break and drink water.\n\nIt is not an expensive item, but it is very useful in my daily life. It helps me stay healthy, and now it feels like part of my routine."
        ),
        SampleAnswer(
            band: "Band 7.0–7.5",
            wordCount: 165,
            content: "I'd like to talk about a stainless-steel water bottle that I use every single day. I got it around two years ago, mainly because I wanted to stop buying bottled drinks all the time.\n\nIn terms of appearance, it's quite plain, just matte black, but that's exactly why I like it. It's lightweight, durable, and easy to carry around, whether I'm commuting, working, or going to the gym. More importantly, it has changed one small but important habit: I now drink water regularly instead of waiting until I feel exhausted.\n\nFor instance, during a busy project last year, I often worked through lunch. Keeping the bottle next to my laptop served as a visual reminder to pause and hydrate. That may sound minor, but it made my afternoons much more productive.\n\nSo although it's a simple object, it has both practical use and a bit of sentimental value, because it represents a healthier lifestyle for me."
        ),
        SampleAnswer(
            band: "Band 8.0+",
            wordCount: 195,
            content: "The object I'd like to describe is a stainless-steel water bottle, which, admittedly, sounds ordinary at first. However, it has had a surprisingly meaningful impact on my daily life. I bought it two years ago when I realized I was relying too much on coffee and barely drinking water during the day.\n\nWhat I appreciate is not just its function but its subtle influence on my behavior. It's compact, durable, and keeps water cold for hours, so it naturally fits into my routine whether I'm in meetings, commuting, or working out. Over time, it has become less of a container and more of a cue for mindful self-care.\n\nI remember a particularly stressful week when deadlines were piling up. I was tempted to power through without breaks, but each time I noticed the bottle on my desk, I took a moment to drink water and reset. That tiny pause helped me stay focused without burning out.\n\nSo, while I wouldn't call it irreplaceable in a literal sense, it's emotionally hard to replace. It reminds me to strike a balance between productivity and well-being, which is something I used to overlook."
        ),
    ]
}

// MARK: - Course Data
enum CourseData {
    static let stages: [Stage] = [
        Stage(
            id: 1,
            title: "Basic Description",
            chineseTitle: "基础描述",
            description: String(localized: "Purpose: Build basic description skills\nGoal: Clearly describe people, objects, and places in 90 seconds."),
            tasks: LessonRepository.loadTasks(forStage: 1)
        ),
        Stage(
            id: 2,
            title: "Events & Early Reflection",
            chineseTitle: "事件叙述与初级认知",
            description: String(localized: "Purpose: Train event narration and initial reflection\nGoal: Tell what happened and why it matters."),
            tasks: LessonRepository.loadTasks(forStage: 2)
        ),
        Stage(
            id: 3,
            title: "Process, Problems & Judgment",
            chineseTitle: "过程、问题与判断",
            description: String(localized: "Purpose: Explain processes and decision-making\nGoal: Clearly describe steps, trade-offs, and judgment logic."),
            tasks: LessonRepository.loadTasks(forStage: 3)
        ),
        Stage(
            id: 4,
            title: "Opinions & Comparisons",
            chineseTitle: "观点、比较与不确定性",
            description: String(localized: "Purpose: Enter opinion and comparison topics\nGoal: Express views with flexibility, avoiding extremes."),
            tasks: LessonRepository.loadTasks(forStage: 4)
        ),
        Stage(
            id: 5,
            title: "Real-life Communication",
            chineseTitle: "现实情境与沟通策略",
            description: String(localized: "Purpose: Cover real-life communication scenarios\nGoal: Make requests, refuse, and negotiate with tact."),
            tasks: LessonRepository.loadTasks(forStage: 5)
        ),
        Stage(
            id: 6,
            title: "Workplace Responsibility",
            chineseTitle: "职场表达与责任意识",
            description: String(localized: "Purpose: Enter workplace context and responsibility\nGoal: Report, explain, and handle disagreements steadily."),
            tasks: LessonRepository.loadTasks(forStage: 6)
        ),
        Stage(
            id: 7,
            title: "Relationships & Emotions",
            chineseTitle: "人际关系与情感沟通",
            description: String(localized: "Purpose: Practice authentic but measured interpersonal expression\nGoal: Support, refuse, apologize, and express concern naturally."),
            tasks: LessonRepository.loadTasks(forStage: 7)
        ),
        Stage(
            id: 8,
            title: "Abstract Topics & Values",
            chineseTitle: "抽象话题与价值判断",
            description: String(localized: "Purpose: Transition to abstract value discussions\nGoal: Discuss ideas without being vague."),
            tasks: LessonRepository.loadTasks(forStage: 8)
        ),
        Stage(
            id: 9,
            title: "Reflection & Self-Positioning",
            chineseTitle: "反思、整合与自我定位",
            description: String(localized: "Purpose: Integrate experience and values into coherent expression\nGoal: Reflect on change and discuss future uncertainty."),
            tasks: LessonRepository.loadTasks(forStage: 9)
        ),
    ]
}
