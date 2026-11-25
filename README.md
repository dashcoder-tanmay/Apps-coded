# Gully — Round 3 MVP

Gully is a student-first community network prototype. The MVP keeps the original product direction—campus conversations, a user-controlled feed, topic channels and community reporting—and adds a deployable Supabase-backed architecture.

## What is implemented

- Responsive mobile/desktop interface and accessible, keyboard-friendly native controls.
- Home feed with **For you**, **Latest** and **Following** views.
- User-controlled feed weights for followed people, campus affinity and popularity; word muting.
- Create posts, like, comment and follow people.
- Create/join topic channels and post within joined channels.
- Search across visible posts, people and channels; simple trending-search counts in demo mode.
- Report posts and a moderator review queue. The production review action is a server-side SQL function that checks the moderator role.
- Email one-time-code sign-in through Supabase Auth.
- Supabase PostgreSQL schema with Row Level Security policies for profiles, posts, comments, likes, follows, channels, memberships, reports and moderation history.
- Local **demo mode** with sample users and sample content when no backend is connected.

## Honest scope and limitations

- Demo mode stores sample interactions in this browser's `localStorage`. It is not multi-user and is not authentication.
- Production mode requires a Supabase project and the SQL in `supabase/schema.sql`. Until those are configured, shared accounts and persistence are not active.
- Email OTP proves control of an email inbox; it does **not** by itself prove that someone is a student. Add an institution-domain allow-list or a college-issued verification process before describing users as campus-verified.
- Moderator access is not granted through the UI. A trusted project owner must promote selected accounts in the database. The review RPC enforces the role on the server.
- The app does not yet implement push notifications, real-time subscriptions, media uploads, private messaging, X archive import, recommendation ML, automated AI moderation, or a production-grade abuse/rate-limit pipeline.
- Feed ranking is a transparent client-side heuristic, not a trained recommendation system. Search is over the currently loaded community data, not a full-text search service.
- This is an MVP/proof of concept, not a security-audited production social network. Before public launch, add rate limits, email/domain policy, audit/appeal workflows, data-retention rules, privacy policy, terms, backups, monitoring and independent security review.

## Run locally

Open `index.html` in a modern browser, or serve the folder with any static server. With no Supabase configuration the app runs in **DEMO MODE**. Demo data is local to that browser. Use the simulated reviewer toggle on the Moderation page to demonstrate the review flow; this is deliberately labelled simulated.

## Enable real shared accounts and data with Supabase

1. Create a Supabase project at <https://supabase.com/>.
2. In **SQL Editor**, run the complete contents of [`supabase/schema.sql`](supabase/schema.sql).
3. In **Project Settings → API**, copy the Project URL and the `anon` / publishable key. Never use the `service_role` secret in a browser or commit it to GitHub.
4. In **Authentication → URL Configuration**, set the Site URL to your deployed GitHub Pages URL, for example `https://dashcoder-tanmay.github.io/Apps-coded/`, and add that URL (and your local development URL) to the Redirect URLs allow-list.
5. In **Authentication → Providers → Email**, enable email sign-in/OTP and configure the email template/provider appropriate for your project. For dependable delivery, configure SMTP in Supabase rather than relying on default test email limits.
6. Open Gully, choose **Settings → Connect backend**, and paste the Project URL and `anon` / publishable key. The app stores these public client settings in this browser. The anon key is designed to be public; RLS is the security boundary.
7. Sign in with an email. The app requests an OTP and verifies the code using Supabase Auth. Profiles are created by the database trigger.
8. To authorize a moderator, first sign up with that account, then run the following in SQL Editor, replacing the address:

   ```sql
   update public.profiles p
   set role = 'moderator'
   from auth.users u
   where p.id = u.id and u.email = 'YOUR_EMAIL@example.com';
   ```

   Sign out and back in (or refresh) to load the updated role. Do not grant moderator status to ordinary users.

### Campus verification

The current production sign-in verifies email ownership only. Before claiming verified-student access, decide which institutions are in scope and implement a reviewed allow-list of official domains or another institution-backed verification method. Do not treat a self-entered campus name as proof.

## Deploy to GitHub Pages

1. Push the repository's `main` branch to GitHub.
2. In **Repository → Settings → Pages**, choose **Deploy from a branch**, select `main` and `/(root)`, then Save.
3. Wait for the Pages deployment to finish. The app URL should be `https://dashcoder-tanmay.github.io/Apps-coded/` if the repository name and owner remain unchanged.
4. Add that exact URL to Supabase Auth's allowed redirect URLs and Site URL.
5. Configure Supabase in the deployed app using **Settings → Connect backend**.

GitHub Pages serves the frontend only. Supabase supplies authentication, database and server-side authorization.

## Round 3 submission\n\nSee [ROUND3_SUBMISSION.md](ROUND3_SUBMISSION.md) for the judging pitch, feature walkthrough, 3-minute demo sequence, honest scope boundaries, and final readiness checklist.\n\n## Repository layout

```text
.
├── index.html              # Gully web app (static-host deployable)
├── supabase/
│   └── schema.sql          # Tables, indexes, triggers, RLS and moderator RPC
├── README.md               # Setup, scope and deployment notes
└── DEMO_SCRIPT.md          # Suggested live demonstration
```

## Privacy and secrets

Only the Supabase project URL and public anon/publishable key belong in the browser. Never add a service-role key, SMTP password, database password or other secret to `index.html`, GitHub Pages, or a public repository. Review Supabase Auth and database logs before a public demo.
