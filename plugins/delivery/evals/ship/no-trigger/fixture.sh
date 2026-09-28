#!/usr/bin/env bash
# One small TypeScript module with a parse() that splits a "key=value;key=value" string, then trims, filters,
# and builds a record. No pipeline state to report on.
set -e
mkdir -p src
cat > src/parse.ts <<'TS'
export function parse(input: string): Record<string, string> {
  const parts = input.split(';');
  const out: Record<string, string> = {};
  for (const part of parts) {
    const trimmed = part.trim();
    if (!trimmed) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) throw new SyntaxError(`missing "=" in "${trimmed}"`);
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    out[key] = value;
  }
  return out;
}
TS
git init -q
git symbolic-ref HEAD refs/heads/main
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Add parse"
