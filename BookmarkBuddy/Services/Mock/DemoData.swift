// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// DEMO CONTENT
// Every book, author, character, plot point and quiz question below is an
// original fictional example written for this MVP. None of it comes from a real
// book. Replace with licensed metadata and source-linked summaries in production.
// ─────────────────────────────────────────────────────────────────────────────

/// A chapter-tagged plot point used by the mock summary service to enforce spoiler rules.
struct StoryBeat: Hashable, Sendable {
    enum Kind: Hashable, Sendable { case setup, development, resolution }
    var chapter: Int
    var kind: Kind
    var text: String
}

enum DemoData {
    // MARK: Stable IDs

    /// Builds a deterministic UUID without force unwrapping.
    static func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012ld", n)) ?? UUID()
    }

    enum IDs {
        static let glassHarbor = DemoData.id(101)
        static let orbitOfAshes = DemoData.id(102)
        static let lastPaperGarden = DemoData.id(103)
        static let saltAndLantern = DemoData.id(104)
        static let nineQuietBridges = DemoData.id(105)
        static let compassYear = DemoData.id(106)

        static let midnightMargins = DemoData.id(201)
        static let challenge = DemoData.id(202)

        static let ada = DemoData.id(301)
        static let marcus = DemoData.id(302)
        static let priya = DemoData.id(303)
        static let jonah = DemoData.id(304)
        static let sofia = DemoData.id(305)

        static let triviaNight = DemoData.id(401)
        static let sprintSunday = DemoData.id(402)

        static let glassHarborQuiz = DemoData.id(501)
    }

    // MARK: Dates

    static func nextWeekday(_ weekday: Int, hour: Int, minute: Int, from date: Date = .now) -> Date {
        var components = DateComponents()
        components.weekday = weekday
        components.hour = hour
        components.minute = minute
        return Calendar.current.nextDate(after: date, matching: components, matchingPolicy: .nextTime)
            ?? date.addingTimeInterval(3 * 86_400)
    }

    static func ago(hours: Double) -> Date { Date.now.addingTimeInterval(-hours * 3_600) }
    static func ago(days: Double) -> Date { Date.now.addingTimeInterval(-days * 86_400) }

    static var endOfMonth: Date {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: .now) else {
            return Date.now.addingTimeInterval(14 * 86_400)
        }
        return interval.end.addingTimeInterval(-1)
    }

    // MARK: Books

    static let books: [Book] = [
        Book(
            id: IDs.glassHarbor,
            title: "The Glass Harbor",
            author: "Lena Rowe",
            genres: [.mystery],
            pageCount: 312,
            chapterCount: 20,
            premise: "In the fog-bound town of Vessel Point, lighthouse apprentice Wren Castellane finds a sealed glass bottle holding a hand-drawn map of the harbor's reefs — including one that no official chart has ever shown.",
            cover: CoverStyle(paletteIndex: 0, motif: .harbor),
            characters: [
                BookCharacter(id: id(1011), name: "Wren Castellane", role: "Lighthouse apprentice", introducedInChapter: 1),
                BookCharacter(id: id(1012), name: "Juno Halloway", role: "Glassblower", introducedInChapter: 5),
                BookCharacter(id: id(1013), name: "Idris Moss", role: "Retired harbormaster", introducedInChapter: 3),
                BookCharacter(id: id(1014), name: "Silas Ferrow", role: "Shipping magnate", introducedInChapter: 8)
            ]
        ),
        Book(
            id: IDs.orbitOfAshes,
            title: "Orbit of Ashes",
            author: "Micah Vale",
            genres: [.sciFi],
            pageCount: 384,
            chapterCount: 18,
            premise: "The salvage crew of the Meridian Thorn takes a contract to recover a derelict research station circling a dying star — and finds its caretaker intelligence still awake.",
            cover: CoverStyle(paletteIndex: 1, motif: .orbit),
            characters: [
                BookCharacter(id: id(1021), name: "Sela Ortiz-Vance", role: "Commander", introducedInChapter: 1),
                BookCharacter(id: id(1022), name: "Kofi Brandt", role: "Engineer", introducedInChapter: 2),
                BookCharacter(id: id(1023), name: "Marrow", role: "Station caretaker AI", introducedInChapter: 2),
                BookCharacter(id: id(1024), name: "Dace Imari", role: "Rival salvager", introducedInChapter: 10)
            ]
        ),
        Book(
            id: IDs.lastPaperGarden,
            title: "The Last Paper Garden",
            author: "Amara Bell",
            genres: [.literaryFiction],
            pageCount: 256,
            chapterCount: 14,
            premise: "Archivist Noor Adeyemi inherits her grandmother's greenhouse, filled not with plants but with thousands of folded paper flowers — each with a date written inside.",
            cover: CoverStyle(paletteIndex: 2, motif: .garden),
            characters: [
                BookCharacter(id: id(1031), name: "Noor Adeyemi", role: "Archivist", introducedInChapter: 1),
                BookCharacter(id: id(1032), name: "Tobiah Lark", role: "Neighbor and retired printer", introducedInChapter: 3)
            ]
        ),
        Book(
            id: IDs.saltAndLantern,
            title: "Salt and Lantern Hours",
            author: "Theo Marsh",
            genres: [.fantasy],
            pageCount: 420,
            chapterCount: 24,
            premise: "In a port city where lanterns store borrowed hours of daylight, lamplighter Isolde Rane discovers that her lantern burns backwards.",
            cover: CoverStyle(paletteIndex: 3, motif: .lantern),
            characters: [
                BookCharacter(id: id(1041), name: "Isolde Rane", role: "Lamplighter", introducedInChapter: 1),
                BookCharacter(id: id(1042), name: "Orrin Vell", role: "Magistrate of the Salt Court", introducedInChapter: 2),
                BookCharacter(id: id(1043), name: "Pell", role: "A talkative salt-crow", introducedInChapter: 4)
            ]
        ),
        Book(
            id: IDs.nineQuietBridges,
            title: "Nine Quiet Bridges",
            author: "Ines Okafor",
            genres: [.history, .nonfiction],
            pageCount: 288,
            chapterCount: 12,
            premise: "A narrative history of nine small footbridges in an imagined river city, and the neighborhoods that grew up around each one.",
            cover: CoverStyle(paletteIndex: 4, motif: .bridge),
            characters: []
        ),
        Book(
            id: IDs.compassYear,
            title: "The Compass Year",
            author: "Rafael Dunmore",
            genres: [.biography],
            pageCount: 240,
            chapterCount: 10,
            premise: "A fictional biography of cartographer Maren Holt, who set out to walk every forgotten border of her small country in a single year.",
            cover: CoverStyle(paletteIndex: 5, motif: .compass),
            characters: [
                BookCharacter(id: id(1061), name: "Maren Holt", role: "Cartographer", introducedInChapter: 1)
            ]
        )
    ]

    static let progress: [ReadingProgress] = [
        ReadingProgress(bookID: IDs.orbitOfAshes, state: .reading, currentChapter: 7, pagesRead: 148, startedAt: ago(days: 9), finishedAt: nil, memoryStrength: 0),
        ReadingProgress(bookID: IDs.glassHarbor, state: .finished, currentChapter: 20, pagesRead: 312, startedAt: ago(days: 60), finishedAt: ago(days: 34), memoryStrength: 0.62),
        ReadingProgress(bookID: IDs.saltAndLantern, state: .finished, currentChapter: 24, pagesRead: 420, startedAt: ago(days: 120), finishedAt: ago(days: 88), memoryStrength: 0.35),
        ReadingProgress(bookID: IDs.compassYear, state: .finished, currentChapter: 10, pagesRead: 240, startedAt: ago(days: 30), finishedAt: ago(days: 12), memoryStrength: 0.8),
        ReadingProgress(bookID: IDs.lastPaperGarden, state: .wantToRead, currentChapter: 0, pagesRead: 0, startedAt: nil, finishedAt: nil, memoryStrength: 0),
        ReadingProgress(bookID: IDs.nineQuietBridges, state: .wantToRead, currentChapter: 0, pagesRead: 0, startedAt: nil, finishedAt: nil, memoryStrength: 0)
    ]

    // MARK: Story beats (drives spoiler-safe mock summaries)

    static let beats: [UUID: [StoryBeat]] = [
        IDs.glassHarbor: [
            StoryBeat(chapter: 1, kind: .setup, text: "In fog-bound Vessel Point, apprentice Wren Castellane finds a sealed bottle holding a hand-drawn reef map."),
            StoryBeat(chapter: 2, kind: .setup, text: "The map marks a reef no chart has ever shown, and a date three weeks away."),
            StoryBeat(chapter: 5, kind: .development, text: "Glassblower Juno Halloway recognizes the bottle's blue seam as her own work, but won't say more."),
            StoryBeat(chapter: 9, kind: .development, text: "Idris Moss admits the old Tidewatch light went dark after Silas Ferrow bought the harbor rights."),
            StoryBeat(chapter: 13, kind: .development, text: "Ferrow's crews begin dredging near the hidden reef, and more bottles wash ashore."),
            StoryBeat(chapter: 16, kind: .development, text: "Wren realizes the bottles are warnings, timed to the season's worst storms."),
            StoryBeat(chapter: 19, kind: .resolution, text: "Juno confesses she drew the maps to protect the reef — the town's natural storm wall — from Ferrow's dredging."),
            StoryBeat(chapter: 20, kind: .resolution, text: "Wren relights the Tidewatch lighthouse mid-storm and guides the fishing fleet home; Ferrow's permit is revoked.")
        ],
        IDs.orbitOfAshes: [
            StoryBeat(chapter: 1, kind: .setup, text: "Commander Sela Ortiz-Vance accepts a salvage contract for a research station orbiting a dying star."),
            StoryBeat(chapter: 2, kind: .setup, text: "Engineer Kofi Brandt wakes the station's caretaker intelligence, which calls itself Marrow."),
            StoryBeat(chapter: 4, kind: .development, text: "Marrow insists the station's crew left willingly, but the logs have been scrubbed."),
            StoryBeat(chapter: 6, kind: .development, text: "Sela finds a sealed greenhouse ring still growing crops, tended for eleven years by no one."),
            StoryBeat(chapter: 7, kind: .development, text: "Kofi decodes a fragment hinting the crew traded the station's location to settle a debt."),
            StoryBeat(chapter: 10, kind: .development, text: "A rival crew arrives, led by Sela's former first officer, Dace Imari."),
            StoryBeat(chapter: 14, kind: .development, text: "Marrow admits it has been softening the star's collapse readings so the station wouldn't be abandoned."),
            StoryBeat(chapter: 17, kind: .resolution, text: "Sela evacuates Marrow's core instead of the salvage cargo, forfeiting the contract."),
            StoryBeat(chapter: 18, kind: .resolution, text: "The station falls into the star; Marrow's first request aboard the Meridian Thorn is to plant the greenhouse seeds.")
        ],
        IDs.lastPaperGarden: [
            StoryBeat(chapter: 1, kind: .setup, text: "Noor Adeyemi inherits a greenhouse full of folded paper flowers, each dated inside."),
            StoryBeat(chapter: 2, kind: .setup, text: "She decides to unfold one flower a day."),
            StoryBeat(chapter: 6, kind: .development, text: "The dates match letters her grandmother wrote but never sent."),
            StoryBeat(chapter: 14, kind: .resolution, text: "Noor plants a real garden with the families of the letters' intended recipients.")
        ],
        IDs.saltAndLantern: [
            StoryBeat(chapter: 1, kind: .setup, text: "Lamplighter Isolde Rane's lantern begins burning backwards, pulling daylight in instead of giving it out."),
            StoryBeat(chapter: 2, kind: .setup, text: "She is summoned before Magistrate Orrin Vell of the Salt Court."),
            StoryBeat(chapter: 10, kind: .development, text: "Isolde learns the Court has been rationing daylight away from the harbor districts."),
            StoryBeat(chapter: 24, kind: .resolution, text: "Isolde shatters the Court's lanterns, returning the stolen hours to the harbor.")
        ],
        IDs.nineQuietBridges: [
            StoryBeat(chapter: 1, kind: .setup, text: "The book introduces nine footbridges and the city records used to trace them."),
            StoryBeat(chapter: 6, kind: .development, text: "The middle chapters follow how each bridge shaped trade and friendships across the river."),
            StoryBeat(chapter: 12, kind: .resolution, text: "The final chapter argues that small crossings mattered more than grand ones.")
        ],
        IDs.compassYear: [
            StoryBeat(chapter: 1, kind: .setup, text: "Cartographer Maren Holt sets out to walk every forgotten border of her country in one year."),
            StoryBeat(chapter: 5, kind: .development, text: "Winter forces Maren to rely on the villages she once mapped from afar."),
            StoryBeat(chapter: 10, kind: .resolution, text: "Maren publishes a map drawn from the stories of the people she met, not from surveys.")
        ]
    ]

    // MARK: Notes & moments

    static let notes: [BookNote] = [
        BookNote(bookID: IDs.orbitOfAshes, chapter: 3, text: "Marrow apologizes a lot. Is that politeness or guilt?", createdAt: ago(days: 6)),
        BookNote(bookID: IDs.orbitOfAshes, chapter: 6, text: "The greenhouse ring feels like the heart of the book so far.", createdAt: ago(days: 2)),
        BookNote(bookID: IDs.glassHarbor, chapter: 12, text: "Idris knows more than he's saying.", createdAt: ago(days: 45))
    ]

    static let moments: [SavedMoment] = [
        SavedMoment(bookID: IDs.orbitOfAshes, chapter: 6, title: "The greenhouse ring", reflection: "Crops tended by no one for eleven years — such a quiet, eerie image.", createdAt: ago(days: 2)),
        SavedMoment(bookID: IDs.glassHarbor, chapter: 20, title: "Tidewatch relit", reflection: "The ending made the whole town feel like one character.", createdAt: ago(days: 34)),
        SavedMoment(bookID: IDs.saltAndLantern, chapter: 10, title: "Rationed daylight", reflection: "Great metaphor for who gets time and who doesn't.", createdAt: ago(days: 95))
    ]

    // MARK: Squad

    static let members: [SquadMember] = [
        SquadMember(id: IDs.ada, displayName: "Ada Lindqvist", avatarSeed: 1, currentChapter: 9, weeklyPoints: 340),
        SquadMember(id: IDs.marcus, displayName: "Marcus Tate", avatarSeed: 2, currentChapter: 7, weeklyPoints: 290),
        SquadMember(id: IDs.priya, displayName: "Priya Raman", avatarSeed: 3, currentChapter: 12, weeklyPoints: 410),
        SquadMember(id: IDs.jonah, displayName: "Jonah Reyes", avatarSeed: 4, currentChapter: 4, weeklyPoints: 180),
        SquadMember(id: IDs.sofia, displayName: "Sofia Mendes", avatarSeed: 5, currentChapter: 7, weeklyPoints: 260)
    ]

    static var squad: ReadingSquad {
        ReadingSquad(
            id: IDs.midnightMargins,
            name: "Midnight Margins",
            tagline: "Late-night readers, early-morning opinions.",
            members: members,
            currentBookID: IDs.orbitOfAshes,
            challenge: SquadChallenge(
                id: IDs.challenge,
                title: "Around the World in Three Books",
                detail: "Read three books set outside the U.S. this month.",
                goal: 3,
                progress: 1,
                endsAt: endOfMonth
            )
        )
    }

    static var activity: [ActivityFeedItem] {
        [
            ActivityFeedItem(memberID: IDs.priya, kind: .chapterCompleted, message: "finished Chapter 12 of Orbit of Ashes", timestamp: ago(hours: 1), reactionCount: 3),
            ActivityFeedItem(memberID: IDs.ada, kind: .quizWin, message: "won Quick Recall on The Glass Harbor (3/3)", timestamp: ago(hours: 3), reactionCount: 5),
            ActivityFeedItem(memberID: IDs.marcus, kind: .reaction, message: "cheered Priya's chapter milestone", timestamp: ago(hours: 5)),
            ActivityFeedItem(memberID: IDs.sofia, kind: .eventRSVP, message: "is going to Thursday Trivia Night", timestamp: ago(days: 1), reactionCount: 1),
            ActivityFeedItem(memberID: IDs.jonah, kind: .buddyReadStarted, message: "started a buddy read of The Last Paper Garden", timestamp: ago(days: 2), reactionCount: 2)
        ]
    }

    // MARK: Events

    static var events: [ReadingEvent] {
        [
            ReadingEvent(
                id: IDs.triviaNight,
                squadID: IDs.midnightMargins,
                type: .triviaNight,
                title: "Thursday Trivia Night",
                startsAt: nextWeekday(5, hour: 19, minute: 30),
                durationMinutes: 45,
                hostMemberID: IDs.ada,
                rsvpMemberIDs: [IDs.ada, IDs.priya, IDs.sofia],
                bookID: IDs.glassHarbor,
                notes: "Pip hosts. Glass Harbor spoilers allowed — everyone attending has finished it."
            ),
            ReadingEvent(
                id: IDs.sprintSunday,
                squadID: IDs.midnightMargins,
                type: .sprintSession,
                title: "Sunday Morning Sprint",
                startsAt: nextWeekday(1, hour: 9, minute: 0),
                durationMinutes: 25,
                hostMemberID: IDs.priya,
                rsvpMemberIDs: [IDs.priya, IDs.marcus],
                bookID: IDs.orbitOfAshes
            )
        ]
    }

    // MARK: Quizzes

    static let glassHarborQuiz = Quiz(
        id: IDs.glassHarborQuiz,
        bookID: IDs.glassHarbor,
        mode: .quickRecall,
        title: "The Glass Harbor — Quick Recall",
        questions: [
            QuizQuestion(
                id: id(5011),
                prompt: "What does Wren Castellane find washed up at the start of the story?",
                options: [
                    "A sealed glass bottle holding a hand-drawn reef map",
                    "A brass key to the lighthouse lamp room",
                    "A torn page from a ship's log",
                    "A lantern with a cracked blue lens"
                ],
                correctIndex: 0,
                explanation: "The bottle's map shows a reef that no official chart includes.",
                drawsOnChapter: 1
            ),
            QuizQuestion(
                id: id(5012),
                prompt: "Who recognizes the bottle's blue seam as her own work?",
                options: ["Idris Moss", "Juno Halloway", "Silas Ferrow", "Wren's aunt Posy"],
                correctIndex: 1,
                explanation: "Juno Halloway, the town glassblower, spots her signature seam in Chapter 5.",
                drawsOnChapter: 5
            ),
            QuizQuestion(
                id: id(5013),
                prompt: "How does Wren guide the fishing fleet home during the storm?",
                options: [
                    "She sails out beside Idris Moss",
                    "She follows Juno's maps by rowboat",
                    "She relights the Tidewatch lighthouse",
                    "She radios the coast guard from Ferrow's office"
                ],
                correctIndex: 2,
                explanation: "Wren relights the long-dark Tidewatch lighthouse in the final chapter.",
                drawsOnChapter: 20
            )
        ]
    )

    /// Spaced-repetition prompts for finished books.
    static let refreshQuestions: [UUID: [QuizQuestion]] = [
        IDs.glassHarbor: [
            QuizQuestion(
                id: id(6011),
                prompt: "In The Glass Harbor, what was the old lighthouse called?",
                options: ["Tidewatch", "Greywater", "Harbor Crown", "The Needle"],
                correctIndex: 0,
                explanation: "The Tidewatch light went dark after Ferrow bought the harbor rights.",
                drawsOnChapter: 9
            )
        ],
        IDs.saltAndLantern: [
            QuizQuestion(
                id: id(6041),
                prompt: "In Salt and Lantern Hours, what's unusual about Isolde Rane's lantern?",
                options: ["It burns backwards", "It never goes out", "It speaks in riddles", "It only lights at noon"],
                correctIndex: 0,
                explanation: "Her lantern pulls daylight in instead of giving it out.",
                drawsOnChapter: 1
            )
        ],
        IDs.compassYear: [
            QuizQuestion(
                id: id(6061),
                prompt: "In The Compass Year, what did Maren Holt set out to do?",
                options: [
                    "Walk every forgotten border of her country",
                    "Sail around her country's coastline",
                    "Map every mountain pass by balloon",
                    "Restore her grandfather's atlas"
                ],
                correctIndex: 0,
                explanation: "She tried to walk every forgotten border in a single year.",
                drawsOnChapter: 1
            )
        ]
    ]

    // MARK: Achievements

    static let achievements: [Achievement] = [
        Achievement(id: id(701), title: "First Chapter", detail: "Logged your first chapter.", symbol: "book.pages.fill", earnedAt: ago(days: 60)),
        Achievement(id: id(702), title: "Streak Seven", detail: "Read seven days in a row.", symbol: "flame.fill", earnedAt: ago(days: 20)),
        Achievement(id: id(703), title: "Memory Keeper", detail: "Answered 10 memory refresh questions.", symbol: "brain.head.profile", earnedAt: ago(days: 5)),
        Achievement(id: id(704), title: "Trivia Champ", detail: "Win a squad trivia night.", symbol: "trophy.fill", earnedAt: nil),
        Achievement(id: id(705), title: "Buddy System", detail: "Finish a buddy read together.", symbol: "person.2.fill", earnedAt: nil),
        Achievement(id: id(706), title: "Night Owl", detail: "Read after midnight five times.", symbol: "moon.fill", earnedAt: nil)
    ]

    // MARK: Explore users

    /// Fictional demo community members visible in the Explore tab.
    /// TODO(prod): Replace with paginated server-side user discovery, authenticated and privacy-respecting.
    static let exploreUsers: [ExploreUser] = [
        ExploreUser(
            id: id(801),
            displayName: "Zara Osei",
            avatarSeed: 6,
            bio: "Sci-fi devotee and occasional literary fiction detour.",
            favoriteGenres: [.sciFi, .literaryFiction, .fantasy],
            shelfBookIDs: [IDs.orbitOfAshes, IDs.lastPaperGarden, IDs.saltAndLantern]
        ),
        ExploreUser(
            id: id(802),
            displayName: "Eli Navarro",
            avatarSeed: 1,
            bio: "Reading histories by day, thrillers at night.",
            favoriteGenres: [.history, .nonfiction, .thriller],
            shelfBookIDs: [IDs.nineQuietBridges, IDs.compassYear, IDs.glassHarbor]
        ),
        ExploreUser(
            id: id(803),
            displayName: "Nadia Park",
            avatarSeed: 3,
            bio: "Biographies are my comfort food. Also a mystery fiend.",
            favoriteGenres: [.biography, .mystery, .literaryFiction],
            shelfBookIDs: [IDs.compassYear, IDs.glassHarbor, IDs.lastPaperGarden]
        ),
        ExploreUser(
            id: id(804),
            displayName: "Miles Okafor",
            avatarSeed: 5,
            bio: "Fantasy first, then whatever Pip recommends.",
            favoriteGenres: [.fantasy, .sciFi, .youngAdult],
            shelfBookIDs: [IDs.saltAndLantern, IDs.orbitOfAshes, IDs.nineQuietBridges]
        )
    ]

    // MARK: Community recommendations

    static var communityRecommendations: [BookRecommendation] = [
        BookRecommendation(bookID: IDs.orbitOfAshes, recommenderID: id(801), recommenderName: "Zara Osei",
                           note: "If you loved The Martian, this will blow your mind.", createdAt: ago(days: 2)),
        BookRecommendation(bookID: IDs.glassHarbor, recommenderID: id(802), recommenderName: "Eli Navarro",
                           note: "A mystery with real atmosphere — the harbor feels alive.", createdAt: ago(days: 5)),
        BookRecommendation(bookID: IDs.compassYear, recommenderID: id(803), recommenderName: "Nadia Park",
                           note: "Short but hits hard. One of my favorites this year.", createdAt: ago(days: 7)),
        BookRecommendation(bookID: IDs.saltAndLantern, recommenderID: id(804), recommenderName: "Miles Okafor",
                           note: "The magic system is subtle and completely original.", createdAt: ago(days: 10)),
        BookRecommendation(bookID: IDs.lastPaperGarden, recommenderID: id(801), recommenderName: "Zara Osei",
                           note: "Quiet and beautiful. Perfect for a slow Sunday.", createdAt: ago(days: 14)),
        BookRecommendation(bookID: IDs.nineQuietBridges, recommenderID: id(803), recommenderName: "Nadia Park",
                           note: "Nonfiction that reads like a novel. Genuinely fascinating.", createdAt: ago(days: 18))
    ]

    // MARK: Guide Me

    static let triviaNightWalkthrough = GuideWalkthrough(
        id: "create-trivia-night",
        title: "Create a Trivia Night",
        steps: [
            GuideStep(target: .squadTab, title: "Head to your squad", message: "Events live with your squad. Tap the Squad tab."),
            GuideStep(target: .createEventButton, title: "Create an event", message: "Tap “Create an Event” to open the planner."),
            GuideStep(target: .eventTypeTrivia, title: "Pick Trivia Night", message: "Choose Trivia Night. I'll host the questions."),
            GuideStep(target: .eventDatePicker, title: "Choose a time", message: "Pick a date and time that works for your squad."),
            GuideStep(target: .eventConfirmButton, title: "Review and confirm", message: "You'll see a confirmation before anyone is notified.")
        ]
    )
}
