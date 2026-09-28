---
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Agent]
tags: [walkthrough]
---

Write a handoff to HANDOFF.md for whoever picks this up tomorrow. Context: we're moving session storage from in-memory to Redis. Done: added the redis client and a SessionStore interface. Left: implement RedisSessionStore, switch the app to it behind the SESSION_BACKEND env var, and add an integration test using the redis docker image. Known issue: the in-memory store never expired sessions, so there's no TTL logic to port; Redis needs one (sessions should last 24h).
