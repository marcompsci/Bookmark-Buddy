<div align="center">

<img src="docs/assets/icon.png" width="140" alt="Bookmark Buddy app icon — Bite sitting on an open book" />

# Bookmark Buddy

### *What are you reading — and do you still remember it?*

[![Join the Beta on TestFlight](https://img.shields.io/badge/TestFlight-Join%20the%20Beta-0D96F6?style=for-the-badge&logo=apple&logoColor=white)](https://testflight.apple.com/join/GQRz4n6a)

![iOS 18+](https://img.shields.io/badge/iOS-18%2B-1B4532?style=flat-square&logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-native-B8A9E3?style=flat-square&logo=swift&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-backend-3ECF8E?style=flat-square&logo=supabase&logoColor=white)
![Beta](https://img.shields.io/badge/status-public%20beta-E3B85C?style=flat-square)

</div>

---

## 📲 Join the beta in 60 seconds

<table>
<tr>
<td width="220" align="center">
<img src="docs/assets/testflight-qr.png" width="200" alt="QR code for the Bookmark Buddy TestFlight link" /><br/>
<sub><b>Scan with your iPhone camera</b></sub>
</td>
<td>

**1. Get TestFlight** — install Apple's free [TestFlight app](https://apps.apple.com/app/testflight/id899247664) from the App Store.

**2. Tap the invite** — on your iPhone, open 👉 **[testflight.apple.com/join/GQRz4n6a](https://testflight.apple.com/join/GQRz4n6a)** (or scan the code).

**3. Accept → Install** — Bookmark Buddy lands on your Home Screen with Bite on the cover. 📖

**4. Make your profile** — sign up with your email, then tap the confirmation link we send you (check spam!).

</td>
</tr>
</table>

> 💡 If the link says the beta isn't open yet, Apple is still reviewing the latest build — check back in a few hours.

---

## 🎯 Your tester missions

Try these and tell us how each one felt:

- [ ] **Log your current read** — add the book you're reading on the **Today** tab
- [ ] **Beat the fade** — answer a *"Do you still remember it?"* refresh card
- [ ] **Grow your garden** — open the **Memory Garden** and refresh your weakest memory
- [ ] **Show off your shelf** — build your shelf and share the card with a friend
- [ ] **Meet Bite** — tap the little reading buddy and ask it something

---

## 💬 How to send feedback (it goes straight to us)

| Do this | What happens |
|---|---|
| 📸 **Take a screenshot** anywhere in the app | TestFlight pops up **Share Beta Feedback** — mark it up, add a note, send |
| ✉️ Open **TestFlight → Bookmark Buddy → Send Beta Feedback** | Send a written note any time |
| 💥 **App crashed?** | TestFlight asks to send a crash report — please say yes and add what you were doing |

**Most useful feedback:** what confused you · what you loved · anything that broke · what you wish it did.

---

## ✨ What's inside

- **Today** — one calm screen: what you're reading and what you're about to forget
- **Memory Garden** — every book is a plant; refresh it before it wilts 🌱
- **Refresh schedule** — spaced-repetition nudges so stories actually stick
- **Shareable shelves** — a public shelf at your own handle, plus a share card for socials
- **Bite** — your reading companion, always one tap away

## 🔒 Privacy

Your account, books and notes live in your own profile. Bite only sees what you allow in **Profile → Privacy**, and you can delete your account and data from inside the app.

---

<details>
<summary><b>🛠 For developers</b></summary>

- **Stack:** SwiftUI (iOS 18), Swift 5 mode, `@Observable`, supabase-swift
- **Backend:** Supabase (auth, Postgres with RLS, RPCs). SQL migrations live in `BookmarkBuddy/Docs/`
- **Open:** `BookmarkBuddy.xcodeproj` → scheme **BookmarkBuddy** → run on an iPhone or simulator
- **Feature flags:** `BookmarkBuddy/Config/AppFeatures.swift` (`socialTabs` is off for the beta)
- **Releasing a beta:** bump the build number → **Product › Archive** → **Distribute App › App Store Connect**. New builds auto-flow to the internal group; the **Public Beta** group needs Apple's Beta App Review.

</details>

<div align="center">
<sub>Made by <b>Phoronomic Studios</b> · © 2026 Omari Bell</sub>
</div>
