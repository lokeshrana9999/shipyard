export const meta = {
  name: 'pr-review',
  description: 'Slice the diff, map and review catalog concerns per slice in parallel, check evidence mechanically, validate every finding, compile the report',
  whenToUse: 'Run by the pr-review skill after scope.sh has written full.diff and diff.txt',
  phases: [
    { title: 'Map and review', detail: 'concern-reviewer per slice: map concerns to added lines, then finding with a failure scenario or cleared' },
    { title: 'Validate', detail: 'review-verifier: confirmed | false-positive | pre-existing | duplicate' },
  ],
}

// Every agent inherits the model of the session that invoked the skill: no `model` option anywhere.
// The script has no filesystem access, so the caller passes diff.txt's contents in `diff`.
// args: { worktree, base, scratch, skillDir, diff, files, title, focus, cap, ciRules,
//         securityPaths, sliceLines, maxAgents, singleFiles }
//   worktree     absolute path checked out at the change's head
//   base         base ref (default origin/main)
//   scratch      directory where scope.sh wrote full.diff and diff.txt
//   skillDir     absolute path of the pr-review skill folder
//   diff         the contents of diff.txt ("path:line: code", one added line per line)
//   files        optional: the change's full file list (adds files with no added lines)
//   title, focus optional change title and extra concern from the caller
//   cap          findings cap (default 10); ciRules: optional "rules file; markers" line
//   securityPaths optional list (array or comma-separated) of security-sensitive path fragments
//   sliceLines   added lines per slice (default 400); maxAgents: slice cap (default 6)
//   singleFiles  one slice when files <= this and added <= sliceLines (default 10)

const A = args || {}
if (!A.worktree || !A.scratch || !A.skillDir || typeof A.diff !== 'string') {
  return { error: 'args must include worktree, scratch, skillDir, diff (contents of diff.txt); optionally base, files, title, focus, cap, ciRules, securityPaths, sliceLines, maxAgents, singleFiles' }
}

const REVIEWER = 'delivery:concern-reviewer'
const VERIFIER = 'delivery:review-verifier'
const BASE = A.base || 'origin/main'
const num = (v, d) => (Number(v) > 0 ? Math.floor(Number(v)) : d)
const CAP = num(A.cap, 10)
const SLICE_LINES = num(A.sliceLines, 400)
const MAX_AGENTS = num(A.maxAgents, 6)
const SINGLE_FILES = num(A.singleFiles, 10)
const SECURITY = (Array.isArray(A.securityPaths) ? A.securityPaths : String(A.securityPaths || 'auth, permission, payment, secret, tenant, tenancy').split(','))
  .map((s) => s.trim().replace(/^`|`$/g, '').toLowerCase())
  .filter(Boolean)
const WT = A.worktree
const S = A.scratch
const REF = `${A.skillDir}/references`
const ORDER = { bug: 0, issue: 1, nit: 2 }

// ---------- Scope: parse diff.txt, plan slices (mechanical) ----------
const lines = parseDiff(A.diff)
const byLocation = new Map(lines.map((l) => [l.location, l.code]))
const fileList = uniq([...(Array.isArray(A.files) ? A.files : []), ...lines.map((l) => l.path)]).sort()
if (lines.length === 0) {
  return { report: 'No changes to review.', coverage: null }
}
const plan = planSlices(lines, { sliceLines: SLICE_LINES, maxAgents: MAX_AGENTS, singleFiles: SINGLE_FILES, security: SECURITY })
plan.notes.forEach((n) => log(n))
const slices = plan.slices
log(`${fileList.length} files, ${lines.length} added lines -> ${slices.length} slice(s): ${slices.map((s) => `${s.files.length}f/${s.added}l${s.security ? ' (security)' : ''}`).join(', ')}`)

const CTX = `Change under review: ${A.title || '(untitled)'}
Worktree at the change's head: ${WT}. Base ref: ${BASE}.
Per-file diff: \`git -C ${WT} diff ${BASE}...HEAD -- <path>\`. Base version of a file: \`git -C ${WT} show ${BASE}:<path>\`.
Full unified diff: ${S}/full.diff
Added lines of the whole change, one per line as "path:line: code": ${S}/diff.txt
${A.focus ? `Extra focus from the caller: ${A.focus}\n` : ''}Security-sensitive paths (any path containing one of these): ${SECURITY.join(', ')}. A finding there stays at least an issue unless the guard that makes it safe is named.
Read-only: never edit files, never commit.`

const CATALOG = `Catalog (read all of it):
- ${REF}/catalog.md (entry format), ${REF}/catalog-general.md, ${REF}/catalog-typescript.md, ${REF}/catalog-react.md, ${REF}/catalog-http-api.md, ${REF}/catalog-sql-orm.md, ${REF}/catalog-deploy-config.md
- ${WT}/.claude/shipyard/pr-review/concerns.md, the project's own concerns, if it exists; it wins on id collisions
${A.ciRules ? `- CI-enforced rules: ${A.ciRules}. These map ONLY where an added line in your slice carries a suppression marker.\n` : ''}`

const LOCATION = { type: 'string', description: 'path:line exactly as prefixed in diff.txt' }
const SEVERITY = { type: 'string', enum: ['bug', 'issue', 'nit'] }

const REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    catalogConcernsRead: { type: 'number' },
    mapped: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          canonical_id: { type: 'string', description: 'domain/kebab-id, or adhoc/<slug>' },
          source: { type: 'string', enum: ['starter', 'project', 'adhoc'] },
          sites: {
            type: 'array',
            items: {
              type: 'object',
              properties: { location: LOCATION, code_line: { type: 'string', description: 'the added code, verbatim' } },
              required: ['location', 'code_line'],
            },
          },
        },
        required: ['canonical_id', 'sites'],
      },
    },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          canonical_id: { type: 'string' },
          severity: SEVERITY,
          location: LOCATION,
          evidence_line: { type: 'string', description: 'the added code at location, verbatim' },
          description: { type: 'string', description: 'what is wrong and the concrete failure scenario' },
          fix: { type: 'string' },
        },
        required: ['canonical_id', 'severity', 'location', 'evidence_line', 'description', 'fix'],
      },
    },
    cleared: {
      type: 'array',
      items: {
        type: 'object',
        properties: { canonical_id: { type: 'string' }, reason: { type: 'string' } },
        required: ['canonical_id', 'reason'],
      },
    },
  },
  required: ['catalogConcernsRead', 'mapped', 'findings', 'cleared'],
}

const VALIDATE_SCHEMA = {
  type: 'object',
  properties: {
    verdicts: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          verdict: { type: 'string', enum: ['confirmed', 'false-positive', 'pre-existing', 'duplicate'] },
          duplicate_of: { type: 'string' },
          final_severity: SEVERITY,
          reason: { type: 'string' },
        },
        required: ['id', 'verdict', 'final_severity', 'reason'],
      },
    },
    ship_verdict: { type: 'string', description: 'one line, from confirmed findings only' },
  },
  required: ['verdicts', 'ship_verdict'],
}

// ---------- 1 Map and review: one concern-reviewer per slice ----------
phase('Map and review')
const reviews = await parallel(slices.map((slice, i) => () => agent(`${CTX}

${CATALOG}
You are concern-reviewer ${i + 1} of ${slices.length}. Files in the whole change (read any of them for callers, registries, tests):
${fileList.join('\n')}

Your slice${slice.security ? ' (security-sensitive)' : ''}: ${slice.files.length} file(s), ${slice.added} added line(s). Only these lines can be sites or evidence:
${slice.lines.map((l) => l.raw).join('\n')}

Phase 1 MAP: write out every catalog concern with a site in your slice (location verbatim from the lines above, plus the code line); add adhoc/<slug> for a likely defect the catalog doesn't cover.
Phase 2 REVIEW: for each mapped concern, read its sites, callers, callees, and tests; emit a finding only with a concrete failure scenario, else clear it with a reason. Every mapped id must appear in findings or cleared.`,
  { label: `review-slice-${i + 1}`, phase: 'Map and review', agentType: REVIEWER, schema: REVIEW_SCHEMA })))

// ---------- Mechanical check (no model) ----------
const check = checkReviews(reviews, slices, byLocation)
const cov = {
  slices: slices.length,
  read: check.read,
  mapped: check.mapped,
  findings: check.findings.length + check.dropped.length,
  dropped: check.dropped.length,
  confirmed: 0,
  rejected: 0,
  unreviewed: check.unreviewed.length,
}
check.notes.forEach((n) => log(n))
if (check.ran === 0) {
  return { error: 'every concern-reviewer died; nothing was reviewed', coverage: cov }
}
log(`${cov.mapped} mapped, ${cov.findings} findings (${cov.dropped} dropped on evidence check), ${check.cleared.length} cleared, ${cov.unreviewed} unreviewed`)
const findings = check.findings
if (findings.length === 0) {
  const verdict = cov.unreviewed > 0
    ? `No findings, but ${cov.unreviewed} mapped concern(s) or slice(s) went unreviewed; review them before merging`
    : cov.mapped === 0 ? 'Approve: no catalog concern maps onto this diff' : 'Approve: every mapped concern cleared'
  return { coverage: cov, cleared: check.cleared, dropped: check.dropped, unreviewed: check.unreviewed, report: renderReport([], verdict, cov, 0, check) }
}

// ---------- 2 Validate: one review-verifier over every slice's findings ----------
phase('Validate')
const validated = await agent(`${CTX}

Validate every finding below, per your instructions. They come from ${slices.length} reviewer(s), each over one slice of the diff; mark cross-slice duplicates. Base ref for the pre-existing check: ${BASE}.

Findings:
${JSON.stringify(findings, null, 1)}`, { label: 'validate-findings', phase: 'Validate', agentType: VERIFIER, schema: VALIDATE_SCHEMA })

if (!validated) {
  return { error: 'validator died; findings are unvalidated and not reported', coverage: cov, findings }
}

// ---------- Report: mechanical, confirmed findings only ----------
const byId = new Map(validated.verdicts.map((v) => [v.id, v]))
const skipped = findings.filter((f) => !byId.has(f.id))
if (skipped.length > 0) {
  log(`validator skipped ${skipped.map((f) => f.id).join(', ')}; dropped as unvalidated`)
}
const judged = findings.filter((f) => byId.has(f.id)).map((f) => ({ ...f, validation: byId.get(f.id) }))
const confirmed = judged
  .filter((f) => f.validation.verdict === 'confirmed')
  .map((f) => ({ ...f, severity: f.validation.final_severity }))
  .sort((a, b) => ORDER[a.severity] - ORDER[b.severity])
const rejected = judged.filter((f) => f.validation.verdict !== 'confirmed')
cov.confirmed = confirmed.length
cov.rejected = rejected.length + skipped.length
const kept = confirmed.slice(0, CAP)
const overCap = confirmed.length - kept.length
if (overCap > 0) {
  log(`findings cap ${CAP}: ${overCap} confirmed finding(s) left out, lowest severity first`)
}
log(`${confirmed.length} confirmed, ${cov.rejected} rejected`)

return {
  report: renderReport(kept, validated.ship_verdict, cov, overCap, check),
  confirmed,
  rejected,
  cleared: check.cleared,
  dropped: check.dropped,
  unreviewed: check.unreviewed,
  coverage: cov,
}

// ---------- helpers (plain functions, hoisted) ----------

function uniq(xs) {
  return [...new Set(xs)]
}

// diff.txt: "path:line: code". The first ":<digits>: " ends the path.
function parseDiff(text) {
  const out = []
  for (const raw0 of text.split('\n')) {
    const raw = raw0.replace(/\r$/, '')
    const m = raw.match(/^(.*?):(\d+): ?(.*)$/)
    if (!m) continue
    out.push({ raw, path: m[1], line: Number(m[2]), location: `${m[1]}:${m[2]}`, code: m[3] })
  }
  return out
}

// Slicing rule:
//   files <= singleFiles and added <= sliceLines -> one slice.
//   Otherwise files are grouped by top-level directory (root files together) and packed in path
//   order into slices of about sliceLines added lines: a group joins the current slice while it
//   fits, else starts a new one; a group bigger than a slice fills slices file by file (a file is
//   never split). Security-sensitive files are packed the same way into their own slices.
//   Past maxAgents slices, the slice size grows by a quarter until the plan fits, and that's logged.
function planSlices(all, o) {
  const files = new Map()
  for (const l of all) {
    if (!files.has(l.path)) files.set(l.path, [])
    files.get(l.path).push(l)
  }
  const notes = []
  const make = (paths, security) => {
    const ls = paths.flatMap((p) => files.get(p))
    return { files: paths, lines: ls, added: ls.length, security }
  }
  if (files.size <= o.singleFiles && all.length <= o.sliceLines) {
    return { slices: [make([...files.keys()], false)], notes }
  }
  const isSecurity = (p) => o.security.some((s) => p.toLowerCase().includes(s))
  const paths = [...files.keys()].sort()
  const secure = paths.filter(isSecurity)
  const rest = paths.filter((p) => !isSecurity(p))
  const top = (p) => (p.includes('/') ? p.slice(0, p.indexOf('/')) : '.')
  const pack = (ps, size, security) => {
    const groups = []
    for (const p of ps) {
      const last = groups[groups.length - 1]
      if (last && last.key === top(p)) last.paths.push(p)
      else groups.push({ key: top(p), paths: [p] })
    }
    const out = []
    let cur = []
    let n = 0
    const close = () => {
      if (cur.length) out.push(make(cur, security))
      cur = []
      n = 0
    }
    for (const g of groups) {
      const gn = g.paths.reduce((s, p) => s + files.get(p).length, 0)
      if (gn <= size) {
        if (n > 0 && n + gn > size) close()
        cur.push(...g.paths)
        n += gn
        continue
      }
      for (const p of g.paths) {
        const fn = files.get(p).length
        if (n > 0 && n + fn > size) close()
        cur.push(p)
        n += fn
      }
      close()
    }
    close()
    return out
  }
  let size = o.sliceLines
  let slices = [...pack(secure, size, true), ...pack(rest, size, false)]
  if (slices.length > o.maxAgents) {
    const planned = slices.length
    if (o.maxAgents < 2) {
      slices = [make(paths, secure.length > 0)]
    } else {
      while (slices.length > o.maxAgents) {
        size = Math.ceil(size * 1.25)
        slices = [...pack(secure, size, true), ...pack(rest, size, false)]
      }
    }
    notes.push(`${planned} slices exceed the cap of ${o.maxAgents} agents; slices grew to about ${o.maxAgents < 2 ? all.length : size} added lines, ${slices.length} slice(s)`)
  }
  return { slices, notes }
}

function norm(s) {
  return String(s || '').replace(/`/g, '').replace(/\s+/g, ' ').trim()
}

// Drops findings whose evidence_line isn't the added code at `location`, and lists mapped ids
// with no finding and no clearance as unreviewed. A dead reviewer leaves its slice unreviewed.
function checkReviews(results, plannedSlices, diffAt) {
  const notes = []
  const kept = []
  const dropped = []
  const cleared = []
  const unreviewed = []
  let mapped = 0
  let ran = 0
  const reads = []
  let next = 1
  results.forEach((r, i) => {
    const slice = i + 1
    if (!r) {
      notes.push(`slice ${slice} (${plannedSlices[i].files.join(', ')}): reviewer died; unreviewed`)
      unreviewed.push({ canonical_id: '(whole slice)', slice })
      return
    }
    ran++
    reads.push(Number(r.catalogConcernsRead) || 0)
    const ids = uniq((r.mapped || []).map((m) => m.canonical_id))
    mapped += ids.length
    const answered = new Set([...(r.findings || []), ...(r.cleared || [])].map((x) => x.canonical_id))
    for (const id of ids) if (!answered.has(id)) unreviewed.push({ canonical_id: id, slice })
    for (const c of r.cleared || []) cleared.push({ ...c, slice })
    for (const f of r.findings || []) {
      const loc = norm(f.location)
      const code = diffAt.get(loc)
      const ev = norm(f.evidence_line)
      const row = { id: `F${next++}`, slice, ...f, location: loc }
      if (code !== undefined && ev !== '' && norm(code).includes(ev)) kept.push(row)
      else dropped.push({ ...row, reason: code === undefined ? 'location is not an added line in diff.txt' : 'evidence_line does not match the added code at location' })
    }
  })
  if (dropped.length) notes.push(`evidence check dropped ${dropped.map((f) => `${f.id} (${f.location})`).join(', ')}`)
  if (unreviewed.length) notes.push(`unreviewed: ${unreviewed.map((u) => `${u.canonical_id} (slice ${u.slice})`).join(', ')}`)
  if (uniq(reads).length > 1) notes.push(`reviewers read different catalog sizes: ${reads.join(', ')}; reporting the largest`)
  return { findings: kept, dropped, cleared, unreviewed, mapped, ran, read: reads.length ? Math.max(...reads) : 'n/a', notes }
}

function renderReport(rows, verdict, c, over, chk) {
  const section = (title, sev) => {
    const list = rows.filter((f) => f.severity === sev)
    const body = list.length
      ? list.map((f) => `- \`${f.location}\` — ${f.description} Fix: ${f.fix}\n  > \`${f.evidence_line.trim()}\``).join('\n')
      : '- none'
    return `## ${title}\n${body}`
  }
  const n = (sev) => rows.filter((f) => f.severity === sev).length
  const un = chk && chk.unreviewed.length
    ? `\nUnreviewed: ${chk.unreviewed.map((u) => `${u.canonical_id} (slice ${u.slice})`).join(', ')}`
    : ''
  return `${section('Bugs', 'bug')}

${section('Issues', 'issue')}

${section('Nits', 'nit')}

## Summary
${n('bug')} bugs · ${n('issue')} issues · ${n('nit')} nits${over > 0 ? ` (${over} more over the findings cap)` : ''}. Verdict: ${verdict.replace(/\s*\(advisory\)/gi, '').replace(/[.\s]+$/, '')} (advisory)
Coverage: ${c.slices} slice(s); ${c.read} concerns read; ${c.mapped} mapped; ${c.findings} findings (${c.dropped} dropped on evidence check); ${c.confirmed} confirmed, ${c.rejected} rejected; ${c.unreviewed} unreviewed${un}
Pipeline: workflow.`
}
