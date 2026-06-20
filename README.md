# demo-commit

**This repo exists to prove a single point: you can fake git commits, and a green contribution graph doesn't mean sh*t.**

Every commit in this repository was fabricated. The dates are made up. The "work" is a script appending random computer-science trivia to a single file ([`cs-facts.md`](cs-facts.md)) and stamping each commit with a backdated author date. No real work happened on any of those days.

## Why this matters

Git lets the author set the commit date to literally anything:

```bash
GIT_AUTHOR_DATE="2026-06-19T12:00:00" GIT_COMMITTER_DATE="2026-06-19T12:00:00" \
  git commit -m "looks legit"
```

GitHub's contribution graph is built from those author dates. So a lush, unbroken streak of green squares proves nothing about when — or whether — anyone actually did anything. Commit counts, streaks, and activity graphs are trivially forgeable and should never be treated as a measure of skill, effort, or output.

## Run it yourself

The whole demonstration is in [`generate-here.sh`](generate-here.sh). It initializes a git repo **in the current directory**, then creates 1–7 backdated `[DEMO]` commits per day (with timestamps scattered across waking hours) going back however many days you ask for. It never deletes anything, never adds a remote, and never pushes.

```bash
# 1. Make an empty folder for the demo and step into it
mkdir fake-streak && cd fake-streak

# 2. Run the script (DAYS defaults to 365)
bash /path/to/generate-here.sh 365

# 3. Look at what it produced
git log --pretty='%h  %ad  %s' --date=short
```

Pass a different number to control how far back the fake history goes:

```bash
bash /path/to/generate-here.sh 30   # last 30 days
```

If the current directory already has commits, the script warns you and asks before appending more backdated `[DEMO]` commits on top of the existing history.

### Seeing the fake graph

To watch a contribution graph fill up, create a new repo on GitHub, run the script locally, then push:

```bash
git remote add origin git@github.com:you/fake-streak.git
git push -u origin HEAD
```

Your profile will light up green for dates you never touched a keyboard. That's the whole point.

## Automate it on Vercel (a commit bot)

Want the streak to keep growing without ever running anything yourself? Deploy this repo to Vercel. A [Cron job](vercel.json) fires the serverless function in [`api/cron.js`](api/cron.js) once a day, and it makes **1–7 `[DEMO]` commits** by appending facts to `cs-facts.md` through the GitHub API.

> **Note:** Unlike the bash script, these commits are dated *today* (real-time), not backdated. The bot builds the streak going forward, one day at a time. The commits still count on your contribution graph as long as the token's GitHub account has a verified email.

**Setup:**

1. Create a **fine-grained GitHub personal access token** scoped to this repo with **Contents: Read and write** permission.
2. Import the repo into Vercel (New Project → pick `demo-commit`).
3. In the Vercel project's **Settings → Environment Variables**, add:
   - `GITHUB_TOKEN` — the PAT from step 1.
   - `CRON_SECRET` — any random string (Vercel sends it as the `Authorization` header so only the cron can trigger the function).
   - *(optional)* `GITHUB_OWNER`, `GITHUB_REPO`, `GITHUB_BRANCH` if they differ from the defaults (`Hoshaiah` / `demo-commit` / `main`).
4. Deploy. The cron in [`vercel.json`](vercel.json) runs daily at 12:00 UTC (`0 12 * * *` — change it to whatever you like).

**Caveats:**

- The Vercel **Hobby plan caps cron jobs at once per day**, which is exactly the cadence here. Exact firing time isn't guaranteed.
- To trigger a run manually for testing, hit `https://your-deployment.vercel.app/api/cron` with the header `Authorization: Bearer <CRON_SECRET>`.

## Don't be fooled

- A green contribution graph is not a resume.
- Commit counts and streaks are cosmetic and forgeable.
- Judge code and contributions by their actual content, not by activity metrics.

Everything here is tagged `[DEMO]` and is purely educational.
