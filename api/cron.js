// api/cron.js — EDUCATIONAL DEMO (Vercel Cron variant)
//
// Same lesson as generate-here.sh, but it runs on Vercel: a Cron job invokes
// this function once a day, and it creates 1-7 [DEMO] commits by appending
// computer-science trivia to cs-facts.md through the GitHub Contents API.
//
// Every file update through that API is a real commit on the configured
// branch, so the contribution graph fills up without anyone touching a
// keyboard. That's the whole point — a green graph proves nothing.
//
// Required env vars (set in Vercel project settings):
//   GITHUB_TOKEN   fine-grained PAT with Contents: Read and write on the repo
//   CRON_SECRET    (recommended) Vercel sends this as the Authorization header
// Optional overrides:
//   GITHUB_OWNER   default "Hoshaiah"
//   GITHUB_REPO    default "demo-commit"
//   GITHUB_BRANCH  default "main"

const FACTS = [
  "Binary search runs in O(log n) time but requires the input to be sorted first.",
  "The term 'bug' predates computers; Grace Hopper famously taped a real moth into a 1947 logbook.",
  "A hash table gives average O(1) lookup, but worst-case O(n) when every key collides.",
  "TCP guarantees ordered, reliable delivery; UDP trades those guarantees for lower latency.",
  "Big-O describes growth, not speed: an O(n) algorithm can beat an O(log n) one for small n.",
  "There are exactly 1024 bytes in a kibibyte (KiB), but 1000 in a kilobyte (kB).",
  "Quicksort averages O(n log n) but degrades to O(n^2) on already-sorted input with naive pivots.",
  "A SHA-256 hash is 256 bits — 64 hexadecimal characters — regardless of input size.",
  "Floating-point can't represent 0.1 exactly, which is why 0.1 + 0.2 != 0.3 in most languages.",
  "Git stores snapshots, not diffs; identical file contents are stored only once via content hashing.",
  "The halting problem is undecidable: no general algorithm can tell if any program will stop.",
  "Caches exploit locality of reference — recently/nearby-accessed data is likely to be used again.",
  "ASCII uses 7 bits (128 values); UTF-8 extends this to all of Unicode while staying ASCII-compatible.",
  "A balanced binary tree keeps height ~log n, which is what keeps its operations fast.",
  "Deadlock needs four conditions at once: mutual exclusion, hold-and-wait, no preemption, circular wait.",
];

const OWNER = process.env.GITHUB_OWNER || "Hoshaiah";
const REPO = process.env.GITHUB_REPO || "demo-commit";
const BRANCH = process.env.GITHUB_BRANCH || "main";
const TOKEN = process.env.GITHUB_TOKEN;
const FILE = "cs-facts.md";

async function gh(path, opts = {}) {
  const res = await fetch(`https://api.github.com${path}`, {
    ...opts,
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
      "User-Agent": "demo-commit-bot",
      ...(opts.headers || {}),
    },
  });
  if (!res.ok) {
    throw new Error(`GitHub ${opts.method || "GET"} ${path} -> ${res.status}: ${await res.text()}`);
  }
  return res.json();
}

const rand = (n) => Math.floor(Math.random() * n);

export default async function handler(req, res) {
  // Only let Vercel Cron (or someone with the secret) trigger this.
  if (process.env.CRON_SECRET && req.headers.authorization !== `Bearer ${process.env.CRON_SECRET}`) {
    return res.status(401).json({ error: "unauthorized" });
  }
  if (!TOKEN) {
    return res.status(500).json({ error: "GITHUB_TOKEN env var is not set" });
  }

  const day = new Date().toISOString().slice(0, 10);
  const count = rand(7) + 1; // 1-7 commits this run
  const commits = [];

  try {
    for (let f = 1; f <= count; f++) {
      // Re-read the file each time so we always send the latest SHA.
      const current = await gh(`/repos/${OWNER}/${REPO}/contents/${FILE}?ref=${BRANCH}`);
      const content = Buffer.from(current.content, "base64").toString("utf8");

      const fact = FACTS[rand(FACTS.length)];
      const updated = `${content}- **${day}:** ${fact}\n`;

      const result = await gh(`/repos/${OWNER}/${REPO}/contents/${FILE}`, {
        method: "PUT",
        body: JSON.stringify({
          message: `[DEMO] CS fact for ${day} (#${f})`,
          content: Buffer.from(updated, "utf8").toString("base64"),
          sha: current.sha,
          branch: BRANCH,
        }),
      });
      commits.push(result.commit.sha);
    }
  } catch (err) {
    return res.status(502).json({ day, made: commits, error: String(err) });
  }

  return res.status(200).json({ day, count, commits });
}
