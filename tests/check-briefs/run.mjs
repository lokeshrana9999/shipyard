#!/usr/bin/env node
// Fixture test for plugins/shipyard-delivery/skills/build-workflow/scripts/check-briefs.mjs.
// Builds one clean brief set and one set per rule in a temp folder, runs the script on each, and
// checks the clean set exits 0 and every rule set exits 1 printing its rule name.
//
//   node tests/check-briefs/run.mjs

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const script = path.resolve(here, '../../plugins/shipyard-delivery/skills/build-workflow/scripts/check-briefs.mjs');
const root = fs.mkdtempSync(path.join(os.tmpdir(), 'check-briefs-'));
const emptyHome = path.join(root, 'home');
fs.mkdirSync(emptyHome);

const CONFIG = [
  '# Models for the fixture project',
  'Prose lines like this one are ignored.',
  'implement: opus', 'fixer: opus', 'verify: opus', 'live-plan: opus',
  'test-design: opus', 'reader: sonnet', 'live-run: sonnet',
].join('\n');

function brief({ role, models, owned = [], report, folder = 'C:\\work\\app', seat, continues, prefix, noModel, noFolder }) {
  const lines = [prefix ?? `Shared prefix for ${role}: rules every ${role} brief in this run repeats byte for byte.`, '---'];
  if (seat) lines.push(`Seat: ${seat}`);
  if (continues) lines.push(`Continues: ${continues}`);
  lines.push('## Background', 'Fixture.', '', '## Task', `One ${role} task.`, '', '## Files owned');
  lines.push(...(owned.length ? owned.map((p) => `- \`${p}\``) : ['- none (read-only)']));
  if (!noModel) lines.push('', '## Model per role', ...(models ?? [`- ${role}: ${role === 'reader' || role === 'live-run' ? 'sonnet' : 'opus'}`]));
  if (!noFolder) lines.push('', '## Working folder', `\`${folder}\``);
  lines.push('', '## Report', '- First action: write your working folder (the output of `pwd`) as the first line of the report.', `- When done, write \`${report ?? `C:\\work\\reports\\${role}.md`}\`.`);
  return lines.join('\n') + '\n';
}

const clean = {
  'implement-1': brief({ role: 'implement', seat: 'builder', owned: ['src/auth/login.ts'] }),
  'fixer-1': brief({ role: 'fixer', seat: 'builder', continues: 'implement-1', owned: ['src/auth/login.ts'] }),
  'verify-1': brief({ role: 'verify', seat: 'checker' }),
  'live-plan-1': brief({ role: 'live-plan', seat: 'checker', continues: 'verify-1' }),
  'test-design-1': brief({ role: 'test-design', owned: ['test/auth/login.test.ts'] }),
  'reader-1': brief({ role: 'reader' }),
  'reader-2': brief({ role: 'reader' }),
};

const cases = {
  clean: { briefs: clean, expect: null },
  overlap: { expect: 'overlap', briefs: {
    'implement-1': brief({ role: 'implement', owned: ['src/auth/'] }),
    'test-design-1': brief({ role: 'test-design', owned: ['src/auth/login.ts'] }) } },
  'report-path': { expect: 'report-path', briefs: { 'reader-1': brief({ role: 'reader', report: 'reports/reader.md' }) } },
  'model-missing': { expect: 'model-missing', briefs: { 'reader-1': brief({ role: 'reader', noModel: true }) } },
  'unknown-role': { expect: 'unknown-role', briefs: { 'reader-1': brief({ role: 'reader', models: ['- reader: sonnet', '- implementer: opus'] }) } },
  'bad-value': { expect: 'bad-value', briefs: { 'reader-1': brief({ role: 'reader', models: ['- reader: gpt5'] }) } },
  'model-mismatch': { expect: 'model-mismatch', briefs: { 'reader-1': brief({ role: 'reader', models: ['- reader: opus'] }) } },
  'working-folder': { expect: 'working-folder', briefs: { 'reader-1': brief({ role: 'reader', folder: 'work/app' }) } },
  'working-folder-absent': { expect: 'working-folder', briefs: { 'reader-1': brief({ role: 'reader', noFolder: true }) } },
  'seat-model-split': { expect: 'seat-model-split', config: CONFIG.replace('fixer: opus', 'fixer: sonnet'), briefs: {
    'implement-1': brief({ role: 'implement', seat: 'builder', owned: ['src/a.ts'] }),
    'fixer-1': brief({ role: 'fixer', seat: 'builder', continues: 'implement-1', owned: ['src/a.ts'], models: ['- fixer: sonnet'] }) } },
  'seat-mixes-checker': { expect: 'seat-mixes-checker', briefs: {
    'implement-1': brief({ role: 'implement', seat: 'builder', owned: ['src/a.ts'] }),
    'verify-1': brief({ role: 'verify', seat: 'builder' }) } },
  'prefix-drift': { expect: 'prefix-drift', briefs: {
    'reader-1': brief({ role: 'reader' }),
    'reader-2': brief({ role: 'reader', prefix: 'Shared prefix for reader, edited by hand.' }) } },
  'orphan-continuation': { expect: 'orphan-continuation', briefs: {
    'fixer-1': brief({ role: 'fixer', continues: 'implement-9 (round 1)', owned: ['src/a.ts'] }) } },
  'overlap-annotated': { expect: 'overlap', briefs: {
    'implement-1': brief({ role: 'implement', owned: ['src/a.ts'] }),
    'test-design-1': brief({ role: 'test-design', owned: ['src/a.ts` (new)'] }) } },
  'config-comment': { expect: 'bad-value', config: CONFIG.replace('reader: sonnet', 'reader: sonnet  # cheap'), briefs: {
    'implement-1': brief({ role: 'implement', owned: ['src/a.ts'] }) } },
};

let failed = 0;
for (const [name, c] of Object.entries(cases)) {
  const project = path.join(root, name);
  const folder = path.join(project, 'briefs');
  fs.mkdirSync(path.join(project, '.claude', 'shipyard'), { recursive: true });
  fs.mkdirSync(folder);
  fs.writeFileSync(path.join(project, '.claude', 'shipyard', 'models.md'), c.config ?? CONFIG);
  for (const [file, text] of Object.entries(c.briefs)) fs.writeFileSync(path.join(folder, `${file}.md`), text);
  const r = spawnSync(process.execPath, [script, folder, '--project', project, '--home', emptyHome], { encoding: 'utf8' });
  const out = (r.stdout + r.stderr).trim();
  const rules = [...new Set(out.split('\n').map((l) => l.split(':')[0]).filter((x) => x && x !== 'ok'))];
  const ok = c.expect === null
    ? r.status === 0
    : r.status === 1 && rules.length === 1 && rules[0] === c.expect;
  if (!ok) failed++;
  console.log(`${ok ? 'pass' : 'FAIL'}  ${name.padEnd(22)} exit=${r.status} rules=${rules.join(',') || '-'}`);
  if (!ok) console.log(out.replace(/^/gm, '      '));
}
// The script must still run when its own path has a space (common Windows user folders).
const spaced = path.join(root, 'dir with space');
fs.mkdirSync(spaced);
fs.copyFileSync(script, path.join(spaced, 'check-briefs.mjs'));
const sr = spawnSync(process.execPath, [path.join(spaced, 'check-briefs.mjs'), path.join(root, 'no-such-folder')], { encoding: 'utf8' });
const spacedOk = sr.status === 2;
if (!spacedOk) failed++;
console.log(`${spacedOk ? 'pass' : 'FAIL'}  ${'path-with-space'.padEnd(22)} exit=${sr.status} (want 2: missing folder is a usage error)`);
fs.rmSync(root, { recursive: true, force: true });
console.log(failed ? `${failed} case(s) failed` : `all ${Object.keys(cases).length} cases pass`);
process.exit(failed ? 1 : 0);
