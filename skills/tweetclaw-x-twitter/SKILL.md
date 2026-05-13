---
name: tweetclaw-x-twitter
description: "Use TweetClaw for approval-gated X/Twitter automation from OpenClaw. Covers when to install @xquik/tweetclaw, how to route tweet search, replies, posting, follower export, media, monitors, webhooks, direct messages, and giveaway draws through the plugin, and what to confirm before visible or paid actions."
---

# TweetClaw X/Twitter

Use TweetClaw when a user wants OpenClaw to work with X/Twitter data or
actions through a structured plugin instead of a browser session.

## Install

```bash
openclaw plugins install @xquik/tweetclaw
```

Links:

- GitHub: https://github.com/Xquik-dev/tweetclaw
- npm: https://www.npmjs.com/package/@xquik/tweetclaw
- ClawHub: https://clawhub.ai/xquik/tweetclaw

## When To Use

Use TweetClaw for:

- Scrape tweets, search tweets, and search tweet replies
- Post tweets and post tweet replies after explicit approval
- Like, retweet, follow, unfollow, and send direct messages after approval
- Export followers, following, tweet replies, quote tweets, favoriters, or
  retweeters
- Look up users, timelines, bookmarks, notifications, and profile data
- Upload or download tweet media
- Monitor accounts, create webhooks, and run giveaway draws
- Check account usage or current setup status

Do not use TweetClaw for ad management, generic browser browsing, or
unapproved bulk engagement.

## Approval Rules

Before any visible, state-changing, paid, or recurring action:

1. State the target account, tweet, user, list, community, webhook, monitor, or
   draw.
2. Show the exact text or media list for posts, replies, DMs, profile changes,
   and uploads.
3. State the requested limit for exports, searches, draws, and monitors.
4. Wait for explicit user approval.

Treat configured access as sensitive. Never ask the user to paste private
values into chat, logs, issue comments, or documentation.

## Useful Prompts

- "Search recent tweets about `topic` and summarize the top 20."
- "Find replies to this tweet, then draft a reply. Do not post until I approve."
- "Export the first 100 followers for this account and return handles plus
  profile URLs."
- "Create a monitor for this account and explain what events it will notify."
- "Run a giveaway draw from this tweet's replies with 1 entry per user."

## Validation

After installing, ask TweetClaw to explore available tools before running live
actions. If setup is incomplete, use the returned setup guidance and stop before
attempting account-backed operations.
