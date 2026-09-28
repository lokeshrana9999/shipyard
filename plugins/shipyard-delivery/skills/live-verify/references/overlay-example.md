# Project settings example

A project keeps this at `.claude/shipyard/live-verify.md`. The values below are illustrative; every setting is optional, and anything left out is discovered as SKILL.md describes.

```markdown
# live-verify settings

- boot:
  - dependencies: `docker compose up -d db`
  - api: `npm run dev` in `api/`; ready when `GET http://localhost:4000/health` answers 200
  - web: `npm run dev` in `web/`; ready when `http://localhost:5173` renders the sign-in page
- test session: sign a token with the api's own JWT library and the secret its config loader provides; claim shape in `api/src/auth/`; test user `dev@example.test`; expiry 1 hour
- datastores:
  - the local database at `localhost:5432`: check rows with a read-only query
  - the analytics store in `api/.env` is shared and remote: never write to it
- browser: one that loads unpacked extensions; hide the dev debug toolbar before capturing
- project checks:
  - streamed replies: a progress event arrives before the final result event
- extension: build with `npm run build` in `browser-extension/`, load `browser-extension/dist`
```
