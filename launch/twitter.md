# X/Twitter Thread

---

## Tweet 1 (Hook)

Managing 10+ Git repos is painful.

Status across all? Shell scripts.
Branch on all? More scripts.
Sync all? You get the idea.

I built something better.

🧵

---

## Tweet 2 (Solution)

Introducing Mars — a polyrepo workspace manager.

One CLI for:
→ init/clone/status across all repos
→ Tag-based filtering (--tag frontend)
→ Parallel operations (4 concurrent jobs)
→ Cross-repo branching & sync

Pure bash 3.2+, zero dependencies.

---

## Tweet 3 (Differentiator)

The killer feature: tag-based filtering.

Tag repos by team or function, then target any operation at a subset:

`mars exec "npm test" --tag frontend`

No more "run this everywhere and hope for the best."

---

## Tweet 4 (CTA)

Install in 10 seconds:

```
npm i -g @dean0x/mars
```

or `brew install dean0x/tap/mars`

GitHub: github.com/dean0x/mars

[Attach demo.gif]
