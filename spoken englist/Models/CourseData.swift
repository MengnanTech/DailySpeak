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

    var title: String {
        switch self {
        case .strategy:   "答题策略"
        case .vocabulary:  "核心词汇"
        case .phrases:     "实用词组"
        case .framework:   "表达框架"
        case .samples:     "范文学习"
        case .practice:    "口语练习"
        }
    }

    var englishTitle: String {
        switch self {
        case .strategy:   "Strategy & Tips"
        case .vocabulary:  "Key Vocabulary"
        case .phrases:     "Useful Phrases"
        case .framework:   "Expression Framework"
        case .samples:     "Sample Answers"
        case .practice:    "Guided Practice"
        }
    }

    var subtitle: String {
        switch self {
        case .strategy:   "了解如何组织你的回答"
        case .vocabulary:  "掌握关键词汇和发音"
        case .phrases:     "学习地道表达和例句"
        case .framework:   "掌握答题模板结构"
        case .samples:     "三个等级的优秀范文"
        case .practice:    "实战演练，开口说英语"
        }
    }

    var icon: String {
        switch self {
        case .strategy:   "lightbulb.fill"
        case .vocabulary:  "textbook"
        case .phrases:     "text.quote"
        case .framework:   "rectangle.3.group.fill"
        case .samples:     "doc.richtext.fill"
        case .practice:    "mic.fill"
        }
    }

    var color: Color {
        switch self {
        case .strategy:   Color(hex: "F59E0B")
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

    static let allSteps: [LearningStep] = StepType.allCases.map {
        LearningStep(id: $0.rawValue, type: $0)
    }
}

// MARK: - Vocabulary Item
struct VocabItem: Identifiable {
    let id = UUID()
    let word: String
    let phonetic: String
    let meaning: String
    let band: BandLevel

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
}

// MARK: - Phrase Item
struct PhraseItem: Identifiable {
    let id = UUID()
    let phrase: String
    let example: String
}

// MARK: - Sample Answer
struct SampleAnswer: Identifiable {
    let id = UUID()
    let band: String
    let wordCount: Int
    let content: String
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

    static func placeholder(id: Int, title: String, englishTitle: String, prompt: String) -> SpeakingTask {
        SpeakingTask(
            id: id,
            title: title,
            englishTitle: englishTitle,
            prompt: prompt,
            questionType: "IELTS Speaking Part 2",
            suggestedTime: "准备1分钟；作答1-2分钟",
            difficulty: "L\(id) → L\(id + 1)",
            passCriteria: [
                "无稿连续说满90秒",
                "至少使用6个关键词",
                "至少给出1个具体小故事",
                "长停顿不超过3次"
            ],
            steps: LearningStep.allSteps,
            tips: [
                "先确定描述对象，选择你真正熟悉的",
                "围绕外观、功能、使用场景展开",
                "加入个人经历让回答更生动",
                "使用时间顺序或逻辑顺序组织语言"
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
        VocabItem(word: "practical", phonetic: "/ˈpræktɪkəl/", meaning: "实用的", band: .core),
        VocabItem(word: "durable", phonetic: "/ˈdjʊərəbl/", meaning: "耐用的", band: .core),
        VocabItem(word: "convenient", phonetic: "/kənˈviːniənt/", meaning: "方便的", band: .core),
        VocabItem(word: "lightweight", phonetic: "/ˈlaɪtweɪt/", meaning: "轻便的", band: .core),
        VocabItem(word: "reliable", phonetic: "/rɪˈlaɪəbl/", meaning: "可靠的", band: .core),
        VocabItem(word: "sentimental value", phonetic: "/ˌsentɪˈmentl ˈvæljuː/", meaning: "情感价值", band: .upgrade),
        VocabItem(word: "stay hydrated", phonetic: "/steɪ haɪˈdreɪtɪd/", meaning: "保持水分", band: .upgrade),
        VocabItem(word: "portable", phonetic: "/ˈpɔːrtəbl/", meaning: "便携的", band: .upgrade),
        VocabItem(word: "functional", phonetic: "/ˈfʌŋkʃənl/", meaning: "功能性的", band: .upgrade),
        VocabItem(word: "irreplaceable", phonetic: "/ˌɪrɪˈpleɪsəbl/", meaning: "不可替代的", band: .advanced),
        VocabItem(word: "subtle impact", phonetic: "/ˈsʌtl ˈɪmpækt/", meaning: "微妙影响", band: .advanced),
        VocabItem(word: "mindful habit", phonetic: "/ˈmaɪndfʊl ˈhæbɪt/", meaning: "有意识的习惯", band: .advanced),
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
            description: "学会描述日常事物、人物和地点",
            tasks: [
                .placeholder(id: 1, title: "描述一个物品", englishTitle: "Describe an Object", prompt: "Describe an object you use every day."),
                .placeholder(id: 2, title: "描述一个人", englishTitle: "Describe a Person", prompt: "Describe a person who has influenced you."),
                .placeholder(id: 3, title: "描述一个地方", englishTitle: "Describe a Place", prompt: "Describe a place you like to visit."),
                .placeholder(id: 4, title: "描述一项活动", englishTitle: "Describe an Activity", prompt: "Describe an activity you enjoy doing."),
                .placeholder(id: 5, title: "描述一顿饭", englishTitle: "Describe a Meal", prompt: "Describe a meal you enjoyed recently."),
                .placeholder(id: 6, title: "描述一件衣服", englishTitle: "Describe Clothing", prompt: "Describe a piece of clothing you like."),
                .placeholder(id: 7, title: "描述一种动物", englishTitle: "Describe an Animal", prompt: "Describe an animal you find interesting."),
                .placeholder(id: 8, title: "描述一个房间", englishTitle: "Describe a Room", prompt: "Describe a room you spend time in."),
                .placeholder(id: 9, title: "描述一个工具", englishTitle: "Describe a Tool", prompt: "Describe a tool or device that helps you."),
            ]
        ),
        Stage(
            id: 2,
            title: "Daily Life",
            chineseTitle: "日常生活",
            description: "谈论你的日常习惯和生活方式",
            tasks: [
                .placeholder(id: 1, title: "日常作息", englishTitle: "Daily Routine", prompt: "Describe your typical daily routine."),
                .placeholder(id: 2, title: "饮食习惯", englishTitle: "Eating Habits", prompt: "Talk about your eating habits."),
                .placeholder(id: 3, title: "运动锻炼", englishTitle: "Exercise", prompt: "Describe your exercise routine."),
                .placeholder(id: 4, title: "休闲时光", englishTitle: "Leisure Time", prompt: "How do you spend your free time?"),
                .placeholder(id: 5, title: "购物习惯", englishTitle: "Shopping", prompt: "Describe your shopping habits."),
                .placeholder(id: 6, title: "通勤方式", englishTitle: "Commuting", prompt: "How do you commute to work or school?"),
            ]
        ),
        Stage(
            id: 3,
            title: "People & Relations",
            chineseTitle: "人物关系",
            description: "描述你生活中重要的人物",
            tasks: [
                .placeholder(id: 1, title: "家庭成员", englishTitle: "Family Member", prompt: "Describe a family member you admire."),
                .placeholder(id: 2, title: "好朋友", englishTitle: "Close Friend", prompt: "Talk about your best friend."),
                .placeholder(id: 3, title: "老师", englishTitle: "A Teacher", prompt: "Describe a teacher who influenced you."),
                .placeholder(id: 4, title: "名人偶像", englishTitle: "A Celebrity", prompt: "Talk about a celebrity you admire."),
                .placeholder(id: 5, title: "邻居", englishTitle: "A Neighbor", prompt: "Describe a neighbor you know well."),
                .placeholder(id: 6, title: "同事或同学", englishTitle: "Colleague", prompt: "Describe a colleague or classmate."),
                .placeholder(id: 7, title: "陌生人的善意", englishTitle: "A Kind Stranger", prompt: "Describe a time a stranger helped you."),
                .placeholder(id: 8, title: "童年玩伴", englishTitle: "Childhood Friend", prompt: "Talk about a childhood friend."),
            ]
        ),
        Stage(
            id: 4,
            title: "Places & Travel",
            chineseTitle: "地点旅行",
            description: "描述你去过或想去的地方",
            tasks: [
                .placeholder(id: 1, title: "家乡", englishTitle: "Hometown", prompt: "Describe your hometown."),
                .placeholder(id: 2, title: "旅行经历", englishTitle: "A Trip", prompt: "Describe a memorable trip."),
                .placeholder(id: 3, title: "喜欢的城市", englishTitle: "Favorite City", prompt: "Describe a city you'd like to visit."),
                .placeholder(id: 4, title: "自然风景", englishTitle: "Natural Scenery", prompt: "Describe a beautiful natural place."),
                .placeholder(id: 5, title: "一家餐厅", englishTitle: "A Restaurant", prompt: "Describe a restaurant you enjoy."),
            ]
        ),
        Stage(
            id: 5,
            title: "Events & Experiences",
            chineseTitle: "事件经历",
            description: "分享你的重要经历和难忘时刻",
            tasks: [
                .placeholder(id: 1, title: "难忘的一天", englishTitle: "Memorable Day", prompt: "Describe a day you'll never forget."),
                .placeholder(id: 2, title: "一次成功", englishTitle: "An Achievement", prompt: "Describe something you achieved."),
                .placeholder(id: 3, title: "一次挑战", englishTitle: "A Challenge", prompt: "Describe a challenge you overcame."),
                .placeholder(id: 4, title: "一次聚会", englishTitle: "A Gathering", prompt: "Describe a party or celebration you attended."),
                .placeholder(id: 5, title: "一次迟到", englishTitle: "Being Late", prompt: "Describe a time you were late."),
                .placeholder(id: 6, title: "一次学习新技能", englishTitle: "Learning a Skill", prompt: "Describe a time you learned something new."),
                .placeholder(id: 7, title: "一次帮助别人", englishTitle: "Helping Others", prompt: "Describe a time you helped someone."),
            ]
        ),
        Stage(
            id: 6,
            title: "Media & Entertainment",
            chineseTitle: "媒体娱乐",
            description: "讨论你喜欢的书籍、电影和音乐",
            tasks: [
                .placeholder(id: 1, title: "一本书", englishTitle: "A Book", prompt: "Describe a book that impressed you."),
                .placeholder(id: 2, title: "一部电影", englishTitle: "A Movie", prompt: "Describe a movie you enjoyed."),
                .placeholder(id: 3, title: "一首歌", englishTitle: "A Song", prompt: "Describe a song that is special to you."),
                .placeholder(id: 4, title: "一个电视节目", englishTitle: "A TV Show", prompt: "Describe a TV show you watch regularly."),
                .placeholder(id: 5, title: "一个网站或App", englishTitle: "A Website/App", prompt: "Describe a website or app you use often."),
                .placeholder(id: 6, title: "一则新闻", englishTitle: "A News Story", prompt: "Describe a news story that interested you."),
            ]
        ),
        Stage(
            id: 7,
            title: "Education & Work",
            chineseTitle: "教育工作",
            description: "谈论你的学习和工作经历",
            tasks: [
                .placeholder(id: 1, title: "学校经历", englishTitle: "School Experience", prompt: "Describe your school experience."),
                .placeholder(id: 2, title: "工作经验", englishTitle: "Work Experience", prompt: "Describe a job you have or had."),
                .placeholder(id: 3, title: "未来计划", englishTitle: "Future Plans", prompt: "Describe your future career plans."),
                .placeholder(id: 4, title: "一门课程", englishTitle: "A Course", prompt: "Describe a course you found useful."),
                .placeholder(id: 5, title: "职场技能", englishTitle: "A Work Skill", prompt: "Describe a skill important for your work."),
                .placeholder(id: 6, title: "理想工作", englishTitle: "Dream Job", prompt: "Describe your dream job."),
                .placeholder(id: 7, title: "一次面试", englishTitle: "An Interview", prompt: "Describe a job interview experience."),
                .placeholder(id: 8, title: "在线学习", englishTitle: "Online Learning", prompt: "Describe your online learning experience."),
                .placeholder(id: 9, title: "团队合作", englishTitle: "Teamwork", prompt: "Describe a time you worked in a team."),
            ]
        ),
        Stage(
            id: 8,
            title: "Society & Issues",
            chineseTitle: "社会议题",
            description: "讨论社会热点话题和观点",
            tasks: [
                .placeholder(id: 1, title: "环境保护", englishTitle: "Environment", prompt: "Talk about an environmental issue."),
                .placeholder(id: 2, title: "科技影响", englishTitle: "Technology", prompt: "How has technology changed your life?"),
                .placeholder(id: 3, title: "健康生活", englishTitle: "Health", prompt: "Talk about healthy living."),
                .placeholder(id: 4, title: "城市vs农村", englishTitle: "City vs Rural", prompt: "Compare city and rural life."),
                .placeholder(id: 5, title: "文化差异", englishTitle: "Cultural Differences", prompt: "Talk about cultural differences."),
                .placeholder(id: 6, title: "社交媒体", englishTitle: "Social Media", prompt: "Discuss the impact of social media."),
            ]
        ),
        Stage(
            id: 9,
            title: "Abstract & Advanced",
            chineseTitle: "抽象进阶",
            description: "挑战高难度的抽象话题表达",
            tasks: [
                .placeholder(id: 1, title: "成功的定义", englishTitle: "Success", prompt: "What does success mean to you?"),
                .placeholder(id: 2, title: "幸福感", englishTitle: "Happiness", prompt: "What makes people happy?"),
                .placeholder(id: 3, title: "时间管理", englishTitle: "Time Management", prompt: "How do you manage your time?"),
                .placeholder(id: 4, title: "改变与适应", englishTitle: "Change", prompt: "How do you deal with change?"),
                .placeholder(id: 5, title: "创造力", englishTitle: "Creativity", prompt: "Talk about the importance of creativity."),
            ]
        ),
    ]
}
