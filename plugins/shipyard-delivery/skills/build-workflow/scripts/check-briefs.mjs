#!/usr/bin/env node
// Checks a folder of briefs before an orchestrator dispatches them, and resolves the model per role.
//
//   node check-briefs.mjs <brief folder> [--project <dir>] [--home <dir>]
//   node check-briefs.mjs --resolve [--project <dir>] [--home <dir>]
//
// Every .md file in the folder is one brief, and the folder is checked as one set: the briefs of one
// dispatch. That is every child starting in parallel now, or one seat continuation together with a
// copy of its seat's first brief (so `Continues:` and `prefix-drift` have something to compare).
// A round-2 fresh fixer is its own dispatch, after the builder seat has stopped. Exit 0: all pass. Exit 1: one line
// per failure, `<rule>: <file>: <detail>`. Exit 2: usage error.
//
// Rules (a brief's own role is the first line under `## Model per role`):
//   overlap              two briefs list the same path under ## Files owned (a path ending in / covers
//                        everything under it); briefs with the same `Seat:` value are exempt
//   report-path          the report path under ## Report is missing or not absolute
//   model-missing        ## Model per role is absent or has no `- role: value` line
//   unknown-role         a role not in ROLES below
//   bad-value            a model value not in VALUES below (also checked in the config files)
//   model-mismatch       a brief's value differs from the resolved config
//   working-folder       ## Working folder is absent or not an absolute path
//   seat-model-split     briefs with one `Seat:` value resolve to more than one model
//   seat-mixes-checker   one `Seat:` value holds a producer role and a checker role
//   prefix-drift         two briefs of one role differ before their first `---` line
//   orphan-continuation  `Continues: <name>` names no <name>.md in the folder
//
// Model config (docs/models.md): <project>/.claude/shipyard/models.md, then
// <home>/.claude/shipyard/models.md, then the default. --project defaults to the current folder,
// --home to the user's home folder.

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const ROLES = [
  'reader', 'researcher', 'test-design', 'implement', 'fixer', 'review', 'verify',
  'review-verify', 'live-plan', 'live-run', 'decide', 'frame-check', 'cold-read',
];
const PRODUCERS = new Set(['implement', 'fixer', 'test-design', 'review']);
const CHECKERS = new Set(['verify', 'review-verify', 'live-plan']);
const SMALLER_BY_DEFAULT = new Set(['reader', 'researcher', 'frame-check', 'cold-read', 'live-run']);
const VALUES = new Set(['sonnet', 'opus', 'haiku', 'fable', 'inherit']);

function usage(msg) {
  if (msg) console.error(msg);
  console.error('usage: node check-briefs.mjs <brief folder> [--project <dir>] [--home <dir>]\n'
    + '       node check-briefs.mjs --resolve [--project <dir>] [--home <dir>]');
  process.exit(2);
}

function parseArgs(argv) {
  const opts = { project: process.cwd(), home: os.homedir(), resolve: false, folder: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--resolve') opts.resolve = true;
    else if (a === '--project' || a === '--home') {
      if (!argv[i + 1]) usage(`${a} needs a folder`);
      opts[a.slice(2)] = argv[++i];
    } else if (a.startsWith('--')) usage(`unknown option ${a}`);
    else if (opts.folder) usage('one brief folder only');
    else opts.folder = a;
  }
  if (!opts.resolve && !opts.folder) usage();
  return opts;
}

// A config line counts when its key is a role, `smaller`, or `codex.<role>` (any case); every other
// line is prose. A role line must hold exactly one value: `implement: opus # note` is `bad-value`,
// so a typo never silently falls back to the default.
export function readConfig(file, failures) {
  const out = {};
  if (!fs.existsSync(file)) return out;
  const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
  lines.forEach((line, i) => {
    const m = line.match(/^\s*(?:[-*]\s+)?`?([A-Za-z][A-Za-z.-]*)`?\s*:\s*(.*?)\s*$/);
    if (!m) return;
    const key = m[1].toLowerCase();
    const value = m[2].replace(/^`|`$/g, '');
    if (key.startsWith('codex.')) {
      if (ROLES.includes(key.slice(6)) && /^\S+$/.test(value)) out[key] = value;
      return;
    }
    if (key !== 'smaller' && !ROLES.includes(key)) return;
    if (!VALUES.has(value)) {
      failures.push(`bad-value: ${file}:${i + 1}: ${key}: ${value} (allowed: ${[...VALUES].join(', ')})`);
      return;
    }
    out[key] = value;
  });
  return out;
}

export function resolveModels(project, home, failures = []) {
  const layers = [
    { name: 'project', file: path.join(project, '.claude', 'shipyard', 'models.md') },
    { name: 'user', file: path.join(home, '.claude', 'shipyard', 'models.md') },
  ].map((l) => ({ ...l, values: readConfig(l.file, failures) }));
  const pick = (key) => {
    for (const l of layers) if (l.values[key]) return { value: l.values[key], source: l.name };
    return null;
  };
  const smaller = pick('smaller') || { value: 'inherit', source: 'default' };
  const table = { smaller };
  for (const role of ROLES) {
    table[role] = pick(role)
      || (SMALLER_BY_DEFAULT.has(role)
        ? { value: smaller.value, source: `default (smaller, ${smaller.source})` }
        : { value: 'inherit', source: 'default' });
  }
  return table;
}

function sections(text) {
  const out = {};
  let current = null;
  for (const line of text.split(/\r?\n/)) {
    const h = line.match(/^##\s+(.+?)\s*$/);
    if (h) { current = h[1].toLowerCase(); out[current] = []; continue; }
    if (current) out[current].push(line);
  }
  return out;
}

const isAbsolute = (p) => /^[A-Za-z]:[\\/]/.test(p) || p.startsWith('/') || p.startsWith('\\\\');
const norm = (p) => p.replace(/\\/g, '/');
// The value of a list item or field: its first backticked token, else its first word.
const unquote = (s) => {
  const t = s.trim();
  const tick = t.match(/`([^`]+)`/);
  return tick ? tick[1].trim() : (t.split(/\s+/)[0] || '');
};

export function parseBrief(file) {
  const text = fs.readFileSync(file, 'utf8');
  const s = sections(text);
  const field = (name) => {
    const m = text.match(new RegExp(`^${name}:\\s*(.+)$`, 'mi'));
    return m ? unquote(m[1]) || null : null;
  };
  const owned = (s['files owned'] || [])
    .map((l) => l.match(/^\s*[-*]\s+(.+)$/))
    .filter(Boolean)
    .map((m) => norm(unquote(m[1])))
    .filter((p) => p && !/^none\b/i.test(p));
  const models = (s['model per role'] || [])
    .map((l) => l.match(/^\s*[-*]\s+`?([a-z][a-z-]*)`?\s*:\s*`?([a-z]+)`?/))
    .filter(Boolean)
    .map((m) => ({ role: m[1], value: m[2] }));
  // The report path is the first backticked value that looks like a path (has a separator or ends in .md).
  const reportPath = [...(s.report || []).join('\n').matchAll(/`([^`]+)`/g)]
    .map((m) => m[1].trim())
    .find((v) => /[\\/]/.test(v) || /\.md$/i.test(v)) || null;
  const wf = (s['working folder'] || []).map((l) => l.trim()).find((l) => l);
  const lines = text.split(/\r?\n/);
  const divider = lines.findIndex((l) => l.trim() === '---');
  return {
    file,
    name: path.basename(file, '.md'),
    text,
    owned,
    models,
    role: models[0]?.role || null,
    hasModelSection: 'model per role' in s,
    report: reportPath,
    hasWorkingFolder: 'working folder' in s,
    workingFolder: wf ? unquote(wf) : null,
    seat: field('Seat'),
    continues: field('Continues'),
    prefix: divider >= 0 ? lines.slice(0, divider).join('\n') : null,
  };
}

function overlaps(a, b) {
  if (a === b) return true;
  if (a.endsWith('/') && b.startsWith(a)) return true;
  if (b.endsWith('/') && a.startsWith(b)) return true;
  return false;
}

export function checkFolder(folder, table) {
  const failures = [];
  const files = fs.readdirSync(folder).filter((f) => f.endsWith('.md')).sort();
  const briefs = files.map((f) => parseBrief(path.join(folder, f)));
  const names = new Set(briefs.map((b) => b.name));

  for (const b of briefs) {
    const at = path.basename(b.file);
    if (!b.report || !isAbsolute(b.report)) {
      failures.push(`report-path: ${at}: ${b.report ? `not absolute: ${b.report}` : 'no backticked path under ## Report'}`);
    }
    if (!b.hasModelSection || b.models.length === 0) {
      failures.push(`model-missing: ${at}: ## Model per role ${b.hasModelSection ? 'has no "- role: value" line' : 'is absent'}`);
    }
    for (const { role, value } of b.models) {
      if (!ROLES.includes(role)) { failures.push(`unknown-role: ${at}: ${role}`); continue; }
      if (!VALUES.has(value)) { failures.push(`bad-value: ${at}: ${role}: ${value}`); continue; }
      if (table[role].value !== value) {
        failures.push(`model-mismatch: ${at}: ${role}: ${value}, config resolves ${table[role].value} (${table[role].source})`);
      }
    }
    if (!b.hasWorkingFolder || !b.workingFolder || !isAbsolute(b.workingFolder)) {
      failures.push(`working-folder: ${at}: ${!b.hasWorkingFolder ? '## Working folder is absent' : `not an absolute path: ${b.workingFolder || '(empty)'}`}`);
    }
    if (b.continues && !names.has(b.continues)) {
      failures.push(`orphan-continuation: ${at}: Continues: ${b.continues} has no brief in this folder`);
    }
  }

  for (let i = 0; i < briefs.length; i++) {
    for (let j = i + 1; j < briefs.length; j++) {
      const a = briefs[i];
      const b = briefs[j];
      if (a.seat && a.seat === b.seat) continue;
      for (const pa of a.owned) {
        const hit = b.owned.find((pb) => overlaps(pa, pb));
        if (hit) failures.push(`overlap: ${path.basename(a.file)} and ${path.basename(b.file)}: ${pa} / ${hit}`);
      }
    }
  }

  const bySeat = new Map();
  for (const b of briefs) if (b.seat) bySeat.set(b.seat, [...(bySeat.get(b.seat) || []), b]);
  for (const [seat, group] of bySeat) {
    const roles = [...new Set(group.map((b) => b.role).filter((r) => ROLES.includes(r)))];
    const models = new Set(roles.map((r) => table[r].value));
    if (models.size > 1) {
      failures.push(`seat-model-split: seat ${seat}: ${roles.map((r) => `${r}=${table[r].value}`).join(', ')}`);
    }
    const prod = roles.filter((r) => PRODUCERS.has(r));
    const chk = roles.filter((r) => CHECKERS.has(r));
    if (prod.length && chk.length) {
      failures.push(`seat-mixes-checker: seat ${seat}: producer ${prod.join(', ')} with checker ${chk.join(', ')}`);
    }
  }

  const byRole = new Map();
  for (const b of briefs) if (b.role && b.prefix !== null) byRole.set(b.role, [...(byRole.get(b.role) || []), b]);
  for (const [role, group] of byRole) {
    const first = group[0];
    for (const b of group.slice(1)) {
      if (b.prefix !== first.prefix) {
        failures.push(`prefix-drift: ${path.basename(first.file)} and ${path.basename(b.file)}: role ${role} differs before the --- line`);
      }
    }
  }

  return { failures, count: briefs.length };
}

const real = (p) => { try { return fs.realpathSync(p); } catch { return path.resolve(p); } };
const isMain = Boolean(process.argv[1]) && real(process.argv[1]) === real(fileURLToPath(import.meta.url));
if (isMain) {
  const opts = parseArgs(process.argv.slice(2));
  const configFailures = [];
  const table = resolveModels(opts.project, opts.home, configFailures);
  if (opts.resolve) {
    for (const key of ['smaller', ...ROLES]) console.log(`${key}: ${table[key].value} (${table[key].source})`);
    for (const f of configFailures) console.log(f);
    process.exit(configFailures.length ? 1 : 0);
  }
  if (!fs.existsSync(opts.folder) || !fs.statSync(opts.folder).isDirectory()) usage(`not a folder: ${opts.folder}`);
  const { failures, count } = checkFolder(opts.folder, table);
  const all = [...configFailures, ...failures];
  for (const f of all) console.log(f);
  if (all.length) process.exit(1);
  console.log(`ok: ${count} brief(s) pass`);
}
