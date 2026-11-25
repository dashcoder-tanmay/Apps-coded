# Gully — Round 3 Prototype Submission Notes

## One-line pitch
Gully is a student-first social network for useful campus conversations: a calmer feed, topic-based communities, and transparent community moderation.

## Problem
Large social platforms mix campus-relevant conversations with a high volume of unrelated content. Students need a lightweight place to ask practical questions, find peers, exchange campus knowledge, and participate in focused communities without giving up control of their feed.

## What the prototype demonstrates
- **Three feed modes:** For You, Latest, and Following.
- **User-controlled ranking:** adjustable weights for followed people, campus affinity, and popularity; muted words remain hidden from the feed.
- **Campus community:** optional campus profile and a campus-circle view.
- **Topic channels:** create, discover, join, and post within channels.
- **Social interactions:** publish posts, like, comment, and follow members.
- **Discovery:** search across available posts, people, and channels.
- **Community safety:** report posts with a reason; moderator decisions are checked server-side in the connected backend.
- **Real account flow (when configured):** Supabase email one-time-code authentication.
- **Demo mode:** sample content and local interactions are available without backend credentials.

## What makes Gully different
1. **Feed agency:** users can tune ranking priorities instead of relying on a black-box engagement feed.
2. **Campus-first utility:** channels and campus context make it easier to find relevant people and conversations.
3. **Moderation with accountability:** reports have a review path; production moderation permissions are enforced in PostgreSQL, not by a client-side role switch.
4. **Honest demo/production separation:** sample data is labelled as local demo data; shared accounts and shared persistence require a configured Supabase project.

## Suggested 3-minute demonstration
1. Open Home and compare **For You**, **Latest**, and **Following**.
2. Open **Tune feed** and change the ranking weights; mute a word and show the feed update.
3. Publish a short campus question, like a post, and add a comment.
4. Open **Explore**, search for a campus topic, and open a result.
5. Open **Channels**, create or join a topic channel, then publish a channel post.
6. Open **Campus circle** to show the campus-specific community view.
7. Report a post and show the moderation queue. In demo mode, explicitly call the reviewer toggle simulated; in connected mode, demonstrate a real moderator account only after it has been promoted by the project owner.
8. If the Supabase project is configured, sign in with an email OTP and show that the same data is shared across sessions.

## Architecture
- Static web frontend: HTML, CSS, and JavaScript, deployable on GitHub Pages.
- Supabase Auth: email OTP for real account sessions.
- Supabase PostgreSQL: profiles, posts, comments, likes, follows, channels, memberships, reports, and moderation actions.
- Row Level Security: user-scoped writes and server-side moderator checks.
- SQL RPC: moderation decisions are performed by a database function that verifies moderator permissions.

See [supabase/schema.sql](supabase/schema.sql) for the schema, policies, trigger, and moderation function. See [README.md](README.md) for setup and deployment instructions.

## Scope boundaries — do not overclaim
- Without Supabase configuration, demo mode is local to one browser and is not multi-user authentication.
- Email OTP confirms access to an email inbox; it does not independently prove student status.
- Feed ranking is a transparent heuristic, not machine learning.
- The current MVP does not include push notifications, real-time subscriptions, private messaging, media uploads, X archive import, or automated AI moderation.
- This is a competition MVP/proof of concept, not a security-audited public social network.

## Before the live judging session
- [ ] Enable GitHub Pages and wait for a successful deployment.
- [ ] Create/configure Supabase and run `supabase/schema.sql`.
- [ ] Set Supabase Auth Site URL and Redirect URLs to the deployed Pages URL.
- [ ] Confirm email OTP delivery using a real test inbox.
- [ ] Create a second test account and verify shared posts/comments/likes/follows.
- [ ] Promote only the intended moderator account from the Supabase SQL Editor.
- [ ] Verify a normal account cannot access moderator review actions.
- [ ] Test the app on a phone-sized viewport and a desktop browser.
- [ ] Keep a short screen recording and a fallback demo-mode run ready.
