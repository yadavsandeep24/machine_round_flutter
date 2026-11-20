# Flutter machine coding: interview research (checked 20 Nov 2026)

This note records where each problem branch comes from. **No company publishes its machine-coding questions**, and Flutter-specific reports are much rarer than Android ones. Everything below is a candidate report or a prep-site listing, not a confirmed question.

## How sources were checked
- Web searches across Medium, LeetCode Discuss, Glassdoor, Naukri Code360, Reddit and Flutter prep sites, for Deloitte and similar companies (services firms and Indian product companies).
- Medium pages could not be opened directly (HTTP 403 to automated fetches), so the Medium entries rely on search-result summaries. Open them yourself before relying on details.

## Reports used for branches

| Branch | Company / source | Date | What was asked (paraphrased) | Source |
|---|---|---|---|---|
| `deloitte/users-states-rebuilds` | Deloitte, Flutter developer | Jan 2026 | Round 1: StatelessWidget vs StatefulWidget, widget lifecycle, Future vs Stream. Round 2: live coding, a screen with loading/success/error handling, then optimise a list to reduce rebuilds and explain decisions. Round 3: project and behavioural. | [Medium: My Flutter Interview Experience at Deloitte](https://medium.com/@flutter-interview/my-flutter-interview-experience-at-deloitte-dd0bc95be426) (single first-hand account) |
| `deloitte/users-states-rebuilds` (detail screen) | Techwondoe, Flutter intern | Dec 2025 | Fetch users from an API, list them, open a detail screen on tap. | [Naukri Code360](https://www.naukri.com/code360/interview-experiences/techwondoe/techwondoe-interview-experience-dec-2025-exp-0-2-years) |
| `ecommerce/product-list-cart` | PhonePe (Android) / Nykaa SDE-II Android | Jul 2025 / Aug 2026 | Small e-commerce app with data synced across screens in 90 min; MVVM screen design, then cart, filters and real-time stock. | Reports listed in the Android repo's `docs/INTERVIEW_RESEARCH.md`; PrepFlutter lists "Cart screen" |
| `practice/offline-first-todo` | PrepFlutter Machine Coding track | 2026 | "Offline-first todo app" (Hard) | [prepflutter.com/tracks/live-interview-coding](https://www.prepflutter.com/tracks/live-interview-coding) |
| `practice/login-persistent-session` | PrepFlutter Machine Coding track | 2026 | "Login with persistent session", "Auth refresh that logs users out" (Hard) | same |

## Other signals (no branch)
- **Deloitte job listing (Pune):** asks for unit, widget and integration tests as part of development. ([listing](https://bebee.com/in/jobs/flutter-developer-deloitte-pune-district--whatjobs-4948_905251))
- **Deloitte general guides:** 45–60 minute technical rounds on a shared coding environment; a project deep-dive where you may rewrite logic from your own project; clean, maintainable code valued over speed. (third-party guides, unverified)
- **CRED, Flutter off-campus:** round 1 walked through a take-home API-integration assignment, the hardest part of it, then code snippets to find errors, predict output and improve. ([Medium](https://medium.com/@gawadepooja729/my-cred-flutter-developer-interview-experience-off-campus-f9a56063626e))
- **Freo India (Glassdoor):** a two-hour live Flutter coding round.
- **PrepFlutter machine-coding categories:** Fix the Bug, Code Review, Predict Output, Build UI. Build-UI titles include searchable user directory, movie watchlist, cart screen, one-on-one chat, phone verification flow, discovery card swipe, weight tracker, edit profile. Predict-output titles are mostly event loop, microtasks, streams, `final` vs `const`, equality and `late`. See [DART_FUNDAMENTALS.md](DART_FUNDAMENTALS.md).
- **Not found:** no Flutter-specific machine-coding reports for Accenture, Infosys, TCS, Capgemini, EY or KPMG. For those, expect the Deloitte-style format (fundamentals + a small live screen) and check Glassdoor/AmbitionBox for your specific team.

## Practical takeaway
1. Be able to build a clean list → detail screen with all four states in **45–60 minutes** (`deloitte/*`, `02-posts-list`).
2. Know how to prove a rebuild optimisation, not just claim it.
3. Expect 10–15 minutes of Dart fundamentals and predict-output before coding.
4. Have one take-home-quality project you can walk through and modify live.

## Caveats
Candidate reports are self-reported and vary by team, level and month. Aggregator and prep-site listings are not company statements.
