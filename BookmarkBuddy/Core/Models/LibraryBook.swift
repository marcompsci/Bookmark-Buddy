// Copyright © 2026 Omari Bell. All rights reserved.
// Bookmark Buddy — Unauthorized copying or distribution is prohibited.

import Foundation

struct LibraryQuote: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let note: String?
}

struct LibraryBook: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let author: String
    let genre: String
    let description: String
    let quotes: [LibraryQuote]
}

// MARK: - Catalog

enum BookCatalog {
    static let books: [LibraryBook] = [
        .init(id: "intelligent-investor", title: "The Intelligent Investor", subtitle: "Third Edition", author: "Benjamin Graham", genre: "Finance & Investing", description: "Benjamin Graham's case for investing through analysis instead of emotion, updated with Jason Zweig's chapter-by-chapter commentary for today's markets. This is where Mr. Market, the margin of safety, and the line between investing and speculating come from, and why Warren Buffett keeps pointing people to it.", quotes: [
            .init(text: "The investor's chief problem—and even his worst enemy—is likely to be himself.", note: "Financial failure rarely stems from a lack of intelligence or complex financial analysis. Instead, it comes from letting emotion, like panic during a market drop or greed during a bull market, dictate your financial choices. True investors conquer their own impulses before trying to conquer the market."),
            .init(text: "In the short run, the market is a voting machine, but in the long run, it is a weighing machine.", note: "Short-term stock prices reflect hype, fear, and current trends. Over long time horizons, the market eventually weighs a company's real value, tying price to earnings and fundamental health."),
            .init(text: "An investment operation is one which, upon thorough analysis, promises safety of principal and an adequate return. Operations not meeting these requirements are speculative.", note: "Graham draws a sharp line between real investing and gambling: protecting initial capital comes before the promise of massive returns.")
        ]),
        .init(id: "money-works", title: "Money Works", subtitle: "The Guide to Financial Literacy", author: "Abhijeet Kolapkar", genre: "Finance & Investing", description: "A plain-language primer on personal finance. It walks through budgeting, saving, debt, insurance, and investing, then shows how small, steady decisions add up to real financial freedom. A good first book for anyone who never got this in school.", quotes: [
            .init(text: "The best weight you'll ever lose is the weight of other people's opinion of you.", note: nil),
            .init(text: "Financial literacy is a learnable skill schools never taught you.", note: nil),
            .init(text: "Overconfidence, not ignorance, is what wrecks financial decisions.", note: nil)
        ]),
        .init(id: "let-them-theory", title: "The Let Them Theory", subtitle: nil, author: "Mel Robbins", genre: "Self-Improvement", description: "Mel Robbins builds a whole way of living on two words. Let other people be who they are, then decide what you'll do next. The book shows how much energy comes back when you stop trying to manage things you were never in control of.", quotes: []),
        .init(id: "open", title: "Open", subtitle: "An Autobiography", author: "Andre Agassi", genre: "Memoir & Sport", description: "Andre Agassi, writing with J. R. Moehringer, gives a candid account of a champion who admits he spent much of his career hating the sport he mastered. It follows a childhood built around a ball machine and a demanding father, the rise on tour, and the long search for a life that felt like his own.", quotes: []),
        .init(id: "the-shining", title: "The Shining", subtitle: nil, author: "Stephen King", genre: "Horror", description: "Jack Torrance takes a winter caretaker job at the Overlook Hotel, high in the Colorado Rockies, and brings his wife Wendy and their five-year-old son Danny, who has a gift he doesn't fully understand. Once the snow closes the roads, the hotel begins to take an interest in the family.", quotes: []),
        .init(id: "it", title: "It", subtitle: nil, author: "Stephen King", genre: "Horror", description: "In Derry, Maine, seven kids who call themselves the Losers' Club run up against something that has been feeding on the town's children for a very long time. Decades later, one phone call asks them to come home and keep the promise they made.", quotes: []),
        .init(id: "david-and-goliath", title: "David and Goliath", subtitle: "Underdogs, Misfits, and the Art of Battling Giants", author: "Malcolm Gladwell", genre: "Psychology & Society", description: "Gladwell revisits the oldest underdog story there is and asks what we get wrong about advantages. Using stories from classrooms, battlefields, and hospitals, he argues that the things that look like weaknesses can turn into strengths.", quotes: []),
        .init(id: "the-tipping-point", title: "The Tipping Point", subtitle: "How Little Things Can Make a Big Difference", author: "Malcolm Gladwell", genre: "Psychology & Society", description: "Gladwell's first book looks at how ideas, products, and behaviors spread the way epidemics do. He introduces the Law of the Few, the Stickiness Factor, and the Power of Context to explain how small changes can set off very large ones.", quotes: []),
        .init(id: "outliers", title: "Outliers", subtitle: "The Story of Success", author: "Malcolm Gladwell", genre: "Psychology & Society", description: "Why do some people achieve so much more than everyone else? Gladwell looks past raw talent to the hidden advantages of timing, culture, and opportunity, and makes the case for the 10,000 hours it takes to get truly good at something.", quotes: []),
        .init(id: "the-body-keeps-the-score", title: "The Body Keeps the Score", subtitle: "Brain, Mind, and Body in the Healing of Trauma", author: "Bessel van der Kolk", genre: "Psychology & Society", description: "Psychiatrist Bessel van der Kolk draws on decades of clinical work and research to show how overwhelming experiences reshape the brain and stay lodged in the body. He explains the science in plain language, then surveys paths to recovery, from EMDR, yoga, and neurofeedback to theater and the healing power of safe relationships.", quotes: [
            .init(text: "Trauma is not just an event that took place in the past; it is also the imprint left by that experience on mind, brain, and body.", note: "This quote explains that trauma is an ongoing physical and psychological state, not just a memory of a bad event."),
            .init(text: "The body keeps the score: If the memory of trauma is encoded in our senses, in muscle tension, and in anxiety, then the body must also be involved in the healing process.", note: "It highlights the central thesis of the book: you cannot just talk away trauma with your mind; you must also heal through physical awareness and safety.")
        ]),
        .init(id: "atomic-habits", title: "Atomic Habits", subtitle: "An Easy & Proven Way to Build Good Habits & Break Bad Ones", author: "James Clear", genre: "Self-Improvement", description: "James Clear's practical system for building good habits and dropping bad ones. His argument is that 1% improvements compound, and he lays out the Four Laws of Behavior Change for making a habit obvious, attractive, easy, and satisfying.", quotes: []),
        .init(id: "dont-believe-everything-you-think", title: "Don't Believe Everything You Think", subtitle: "Why Your Thinking Is the Beginning & End of Suffering", author: "Joseph Nguyen", genre: "Self-Improvement", description: "Joseph Nguyen argues that most of our suffering starts with how we think about our circumstances rather than the circumstances themselves. It's a short, direct read on telling the difference between having thoughts and getting lost in them.", quotes: []),
        .init(id: "ikigai", title: "Ikigai", subtitle: "The Japanese Secret to a Long and Happy Life", author: "Héctor García & Francesc Miralles", genre: "Self-Improvement", description: "Héctor García and Francesc Miralles travel to Okinawa, home to some of the longest-lived people on earth, to learn how they live. The book explores ikigai, the reason you get up in the morning, along with the food, movement, friendships, and sense of flow that go with it.", quotes: []),
        .init(id: "the-alchemist", title: "The Alchemist", subtitle: "A Fable About Following Your Dream", author: "Paulo Coelho", genre: "Fiction & Fable", description: "Santiago, a young shepherd from Andalusia, keeps dreaming of treasure buried near the Egyptian pyramids, so he sets out to find it. The people he meets on the way, including a king, a crystal merchant, and an alchemist, teach him to read the omens and listen to his own heart.", quotes: []),
        .init(id: "the-mountain-is-you", title: "The Mountain Is You", subtitle: "Transforming Self-Sabotage into Self-Mastery", author: "Brianna Wiest", genre: "Self-Improvement", description: "Brianna Wiest makes the case that the biggest obstacle in most lives is internal. The book explains where self-sabotage comes from, what it's quietly protecting you from, and how to build the emotional intelligence to get past it.", quotes: []),
        .init(id: "the-art-of-letting-go", title: "The Art of Letting Go", subtitle: "Stop Overthinking, Break Negative Cycles, and Embrace Peace", author: "Lucas Hayes", genre: "Self-Improvement", description: "The first book in Lucas Hayes's Overthinking Cure series offers practical tools for quieting a busy mind. It covers spotting negative thought loops, releasing what you can't control, and building routines that make calm your default.", quotes: [])
    ]

    /// Returns the catalog entry matching a `PersonalShelf` book by title, for enriching display.
    static func entry(forTitle title: String) -> LibraryBook? {
        books.first { $0.title.lowercased() == title.lowercased() }
    }
}
