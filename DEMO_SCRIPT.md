# Gully — 3-minute Round 3 demonstration

## Before the demonstration

- Preferred: configure Supabase, sign in with a test account, create a second test account and prepare one moderator account. Use non-sensitive test data.
- Fallback: open the site in a fresh browser and use Demo Mode. Explain that sample users and interactions are local-only; do not describe them as real accounts or shared data.
- Check the deployed URL, mobile layout, email delivery and network connection. Keep a second browser profile ready to demonstrate multi-user persistence if Supabase is configured.

## Walkthrough

**0:00–0:25 — Problem and product**

“Gully is a student-first community network. Instead of optimizing for paid reach, it makes campus conversations easier to discover and gives people control over what their feed prioritizes.”

**0:25–1:10 — Core social loop**

Show the feed, switch between For you / Latest / Following, publish a short post, like it, reply and follow a student. Point out the “Why this appears” explanation and the feed tuning controls.

**1:10–1:45 — Campus and interest communities**

Show the campus field and student directory, then create or join a topic channel and publish a channel post. Explain that the campus field is not a verified credential in this MVP.

**1:45–2:25 — Trust and safety**

Report a sample post. In the demo build, show the explicitly simulated reviewer mode. In a configured Supabase build, sign in as the separately authorized moderator and show the review queue. Explain that the production review action checks moderator permission on the server and records the decision.

**2:25–3:00 — Architecture, limits and next steps**

Show the repository and `supabase/schema.sql`. Explain that GitHub Pages hosts the static frontend and Supabase provides Auth, PostgreSQL and Row Level Security. State clearly what remains: institutional email-domain verification, AI moderation, rate limiting, notifications, media, realtime and a larger user pilot.

## Claims to avoid

- Do not call Demo Mode a live multi-user platform.
- Do not claim student identity is verified merely because an email OTP succeeded.
- Do not claim automated AI hate-speech detection is implemented in this version.
- Do not claim scalability or production readiness without load/security testing.
