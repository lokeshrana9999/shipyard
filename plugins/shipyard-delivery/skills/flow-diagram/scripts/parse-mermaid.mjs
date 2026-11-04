#!/usr/bin/env node
// Parses every Mermaid diagram in the given files with the official Mermaid parser (the `mermaid` npm
// package, run under jsdom), and warns about syntax the portable subset in references/mermaid-syntax.md
// leaves out. Run it once per diagram before publishing; it replaces repeated self-checks.
//
//   node parse-mermaid.mjs <file.mmd | file.md> [more files...] [--strict] [--no-npx]
//
//   .md / .markdown   every ```mermaid fenced block in the file is one diagram
//   anything else     the whole file is one diagram
//   --strict          portability warnings also fail the run
//   --no-npx          don't fetch the parser with npx when it isn't installed
//
// Exit codes: 0 every diagram parsed (and no warnings with --strict); 1 a diagram failed to parse;
// 2 the parser isn't available, so nothing was parsed (the message says what to do).
//
// Dependencies: node 18 or later, plus the `mermaid` and `jsdom` packages. It looks for them next to this
// script and in the current project; failing that, it re-runs itself through `npx -y -p mermaid -p jsdom`,
// which downloads them into npm's cache on first use (a few MB; needs network). The parser is the one
// renderers use, so a diagram that parses here parses in Mermaid; portability across hosted renderers is
// what the warnings and references/mermaid-syntax.md cover.

import { readFileSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join, delimiter, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

const SELF = fileURLToPath(import.meta.url);
const argv = process.argv.slice(2);
const strict = argv.includes('--strict');
const noNpx = argv.includes('--no-npx');
const child = argv.includes('--child');
const files = argv.filter((a) => !a.startsWith('--'));

if (files.length === 0) {
  console.error('usage: node parse-mermaid.mjs <file.mmd | file.md> [more files...] [--strict] [--no-npx]');
  process.exit(2);
}

const FALLBACK = [
  'parse-mermaid: the Mermaid parser is not available, so no diagram was parsed.',
  'Install it in the project (`npm i -D mermaid jsdom`) or allow npx to fetch it, then run this again.',
  'Until then, check the diagram by hand against references/mermaid-syntax.md and say in the artifact that it was not parsed.',
].join('\n');

// Portability warnings: forms the Mermaid docs allow but hosted renderers often don't (references/mermaid-syntax.md).
const WARNINGS = [
  [/^\s*flowchart\b/m, 'starts with `flowchart`; some renderers accept only `graph`'],
  [/-{4,}>/, 'uses a long arrow (`---->`); some renderers reject it, use `-->`'],
  [/<br\s*\/?>/i, 'uses `<br>` in a label; many renderers strip HTML, so split the node or shorten the label'],
  [/%%\{\s*init/, 'uses an `%%{init}%%` directive; it overrides the page theme and can leave dark arrows on a dark page'],
  [/@\{\s*shape/, 'uses `@{ shape }` syntax; it is not reliable across renderers and may not take a `:::class`'],
  [/\bfa:/, 'uses a `fa:` icon; it needs fonts most hosted renderers do not load'],
  [/^\s*(architecture|block)-beta\b/m, 'uses a beta diagram type; it is not widely supported'],
];

function diagramsIn(path, label) {
  const text = readFileSync(path, 'utf8').replace(/\r\n/g, '\n');
  if (!/\.(md|markdown)$/i.test(path)) return [{ label, text }];
  const out = [];
  const fence = /^(`{3,}|~{3,})\s*mermaid\s*\n([\s\S]*?)^\1\s*$/gm;
  let m;
  while ((m = fence.exec(text)) !== null) out.push({ label: `${label}#${out.length + 1}`, text: m[2] });
  return out;
}

// Find `mermaid` and `jsdom`: next to the script, in the project, or (as the npx child) in npx's cache on PATH.
function locate() {
  const bases = [dirname(SELF), process.cwd()];
  if (child) {
    const bin = (process.env.PATH || '').split(delimiter).find((p) => /_npx/.test(p) && /\.bin$/.test(p));
    if (bin) bases.unshift(dirname(bin));
  }
  for (const base of bases) {
    try {
      const req = createRequire(join(base, 'x.js'));
      return { mermaid: req.resolve('mermaid'), jsdom: req.resolve('jsdom'), version: req('mermaid/package.json').version };
    } catch { /* try the next base */ }
  }
  return null;
}

function viaNpx() {
  const cmd = process.platform === 'win32' ? 'npx.cmd' : 'npx';
  const args = ['-y', '-p', 'mermaid', '-p', 'jsdom', 'node', SELF, '--child', ...argv.filter((a) => a !== '--child')];
  const q = (s) => (/\s/.test(s) ? `"${s.replace(/"/g, '\\"')}"` : s);
  const r = spawnSync(process.platform === 'win32' ? [cmd, ...args.map(q)].join(' ') : cmd, process.platform === 'win32' ? [] : args, {
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
  if (r.error || r.status === null) {
    console.error(FALLBACK);
    process.exit(2);
  }
  process.exit(r.status);
}

async function main() {
  const found = locate();
  if (!found) {
    if (child || noNpx) { console.error(FALLBACK); process.exit(2); }
    return viaNpx();
  }

  const { JSDOM } = await import(pathToFileURL(found.jsdom).href);
  const dom = new JSDOM('<!DOCTYPE html><body></body>', { pretendToBeVisual: true });
  globalThis.window = dom.window;
  globalThis.document = dom.window.document;
  Object.defineProperty(globalThis, 'navigator', { value: dom.window.navigator, configurable: true });
  const mermaid = (await import(pathToFileURL(found.mermaid).href)).default;
  mermaid.initialize({ startOnLoad: false });

  let total = 0, errors = 0, warnings = 0;
  for (const file of files) {
    const path = resolve(file);
    if (!existsSync(path)) { console.log(`error ${file}: no such file`); errors++; continue; }
    const diagrams = diagramsIn(path, file);
    if (diagrams.length === 0) { console.log(`warn  ${file}: no mermaid fenced block found`); warnings++; continue; }
    for (const d of diagrams) {
      total++;
      try {
        const r = await mermaid.parse(d.text, { suppressErrors: false });
        console.log(`ok    ${d.label} ${r?.diagramType ?? ''}`.trimEnd());
      } catch (e) {
        errors++;
        const msg = String(e?.message ?? e).split('\n').filter(Boolean).slice(0, 4).join(' | ');
        console.log(`error ${d.label}: ${msg}`);
      }
      for (const [re, why] of WARNINGS) {
        if (re.test(d.text)) { warnings++; console.log(`warn  ${d.label}: ${why}`); }
      }
    }
  }
  console.log(`${total} diagram${total === 1 ? '' : 's'}, ${errors} error${errors === 1 ? '' : 's'}, ${warnings} warning${warnings === 1 ? '' : 's'} (mermaid ${found.version})`);
  process.exit(errors > 0 || (strict && warnings > 0) ? 1 : 0);
}

main().catch((e) => { console.error(`parse-mermaid: ${e?.message ?? e}`); process.exit(2); });
