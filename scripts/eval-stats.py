#!/usr/bin/env python3
"""Statistics for `claude plugin eval` results (aggregate-result.json).

Usage:
  python scripts/eval-stats.py RESULT.json [RESULT.json ...] [--merge] [--json]
                               [--k 3] [--resamples 10000] [--seed 0] [--keep-errors]

Per case: runs per arm, mean score with/without, paired delta with a 95%
bootstrap CI, baseline pass rate, pass^k for the with arm (empirical "all runs
passed" and the unbiased C(c,k)/C(n,k) estimator), per-grader pass rates per
arm, and flags:
  NON-DISCRIMINATING  baseline (without-arm) pass rate >= 0.8
  NOISY               with-arm score std dev > 0.25
  UNDERPOWERED        delta CI includes 0
  NO-DATA             every run was dropped (errored)
  MIXED-GRADERS       --merge pooled runs whose case had different grader sets
Suite level: mean case delta with a CI from a clustered bootstrap (resample
cases, then runs within each case).

A run "passes" when its score is 1.0. Runs whose `error` is set (session
limits, timeouts, crashes) are dropped unless --keep-errors is given; the
count dropped is reported. Results from `--ablation none` have no without arm:
delta, baseline and the related flags are reported as n/a.

Standard library only (Python 3.10+).
"""
import argparse
import json
import math
import random
import statistics
import sys

PASS_EPS = 1e-9
NONDISC_BASELINE = 0.8
NOISY_SD = 0.25


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def passed(score):
    return score is not None and score >= 1.0 - PASS_EPS


def mean(xs):
    return sum(xs) / len(xs) if xs else None


def sd(xs):
    return statistics.stdev(xs) if len(xs) >= 2 else 0.0


def percentile_ci(samples, alpha=0.05):
    s = sorted(samples)
    n = len(s)
    lo = s[max(0, int(math.floor(alpha / 2 * n)))]
    hi = s[min(n - 1, int(math.ceil((1 - alpha / 2) * n)) - 1)]
    return lo, hi


def resample(rng, xs):
    return [xs[rng.randrange(len(xs))] for _ in xs]


def delta_bootstrap(rng, w, wo, B):
    """Paired bootstrap when the arms have equal run counts (runs paired by
    index), otherwise independent resampling of each arm."""
    if len(w) == len(wo):
        diffs = [a - b for a, b in zip(w, wo)]
        n = len(diffs)
        est = mean(diffs)
        boots = [sum(diffs[rng.randrange(n)] for _ in range(n)) / n for _ in range(B)]
        return est, percentile_ci(boots), "paired"
    est = mean(w) - mean(wo)
    boots = [mean(resample(rng, w)) - mean(resample(rng, wo)) for _ in range(B)]
    return est, percentile_ci(boots), "unpaired"


def pass_hat_k(c, n, k):
    if n < k:
        return None
    return math.comb(c, k) / math.comb(n, k)


def grader_rates(runs):
    tally = {}
    for r in runs:
        for g in r.get("graders") or []:
            t = tally.setdefault(g["name"], {"pass": 0, "n": 0, "withOnly": bool(g.get("withOnly")),
                                             "scored": bool(g.get("scored", True))})
            t["n"] += 1
            t["pass"] += 1 if g.get("passed") else 0
    return {name: {"rate": t["pass"] / t["n"], "n": t["n"], "withOnly": t["withOnly"],
                   "scored": t["scored"]} for name, t in tally.items()}


def collect(files, merge, keep_errors):
    """Return list of groups; each group = (label, {case_name: {"with": [runs], "without": [runs], "dropped": n}})."""
    groups = []
    merged = {}
    for path in files:
        data = load(path)
        target = merged if merge else {}
        for case in data.get("cases", []):
            entry = target.setdefault(case["name"], {"with": [], "without": [], "dropped": 0, "sources": []})
            entry["sources"].append(path)
            entry.setdefault("grader_sets", set()).add(tuple(sorted(g["name"] for g in case.get("graders") or [])))
            for arm in ("with", "without"):
                for r in (case.get("arms") or {}).get(arm) or []:
                    if r.get("score") is None or (r.get("error") and not keep_errors):
                        entry["dropped"] += 1
                        continue
                    entry[arm].append(r)
        if not merge:
            groups.append((path, target))
    if merge:
        groups.append(("merged: " + ", ".join(files), merged))
    return groups


def analyze_case(name, e, rng, B, k):
    w = [r["score"] for r in e["with"]]
    wo = [r["score"] for r in e["without"]]
    out = {"case": name, "n_with": len(w), "n_without": len(wo), "dropped": e["dropped"],
           "mean_with": mean(w), "mean_without": mean(wo), "sd_with": sd(w) if w else None,
           "delta": None, "delta_ci": None, "delta_method": None, "baseline_pass_rate": None,
           "with_pass_rate": None, "k": k, "pass_all_empirical": None, "pass_hat_k": None,
           "graders": {"with": grader_rates(e["with"]), "without": grader_rates(e["without"])},
           "flags": []}
    if w:
        c = sum(passed(s) for s in w)
        out["with_pass_rate"] = c / len(w)
        out["pass_all_empirical"] = c == len(w)
        out["pass_hat_k"] = pass_hat_k(c, len(w), k)
        if out["sd_with"] > NOISY_SD:
            out["flags"].append("NOISY")
    if wo:
        out["baseline_pass_rate"] = sum(passed(s) for s in wo) / len(wo)
        if out["baseline_pass_rate"] >= NONDISC_BASELINE:
            out["flags"].append("NON-DISCRIMINATING")
    if not w and not wo:
        out["flags"].append("NO-DATA")
    if len(e.get("grader_sets", ())) > 1:
        out["flags"].append("MIXED-GRADERS")
    if w and wo:
        est, ci, method = delta_bootstrap(rng, w, wo, B)
        out["delta"], out["delta_ci"], out["delta_method"] = est, list(ci), method
        if ci[0] <= 0 <= ci[1]:
            out["flags"].append("UNDERPOWERED")
    return out


def suite_delta(cases, rng, B):
    """Clustered bootstrap: resample cases, then runs within each sampled case."""
    pairs = [([r["score"] for r in e["with"]], [r["score"] for r in e["without"]])
             for e in cases.values() if e["with"] and e["without"]]
    if not pairs:
        return None
    est = mean([mean(w) - mean(wo) for w, wo in pairs])
    boots = []
    m = len(pairs)
    for _ in range(B):
        ds = []
        for _ in range(m):
            w, wo = pairs[rng.randrange(m)]
            if len(w) == len(wo):
                idx = [rng.randrange(len(w)) for _ in w]
                ds.append(sum(w[i] - wo[i] for i in idx) / len(idx))
            else:
                ds.append(mean(resample(rng, w)) - mean(resample(rng, wo)))
        boots.append(mean(ds))
    return {"cases": m, "mean_delta": est, "ci": list(percentile_ci(boots))}


def fmt(x, nd=2):
    if x is None:
        return "n/a"
    if isinstance(x, bool):
        return "yes" if x else "no"
    return f"{x:.{nd}f}"


def print_group(label, results, suite):
    print(f"== {label}")
    for c in results:
        ci = c["delta_ci"]
        ci_s = f"[{ci[0]:+.2f}, {ci[1]:+.2f}] ({c['delta_method']})" if ci else "n/a"
        delta_s = f"{c['delta']:+.2f}" if c["delta"] is not None else "n/a"
        print(f"\n  {c['case']}  {' '.join(c['flags']) or '-'}")
        print(f"    runs with/without     {c['n_with']}/{c['n_without']}"
              + (f"  (dropped {c['dropped']} errored)" if c["dropped"] else ""))
        print(f"    mean with/without     {fmt(c['mean_with'])} / {fmt(c['mean_without'])}   sd(with) {fmt(c['sd_with'])}")
        print(f"    delta (95% CI)        {delta_s} {ci_s}")
        print(f"    baseline pass rate    {fmt(c['baseline_pass_rate'])}")
        print(f"    with pass rate        {fmt(c['with_pass_rate'])}   all-passed {fmt(c['pass_all_empirical'])}"
              f"   pass^{c['k']} C(c,k)/C(n,k) {fmt(c['pass_hat_k'])}")
        names = list(dict.fromkeys(list(c["graders"]["with"]) + list(c["graders"]["without"])))
        if names:
            width = max(len(n) for n in names) + 2
            print(f"    {'grader':<{width}} with  without")
            for n in names:
                gw, gwo = c["graders"]["with"].get(n), c["graders"]["without"].get(n)
                tag = " (with-only)" if (gw or gwo or {}).get("withOnly") else ""
                print(f"    {n:<{width}} {fmt(gw and gw['rate']):>4}  {fmt(gwo and gwo['rate']):>7}{tag}")
    if suite:
        print(f"\n  SUITE  mean delta {suite['mean_delta']:+.2f}  95% CI "
              f"[{suite['ci'][0]:+.2f}, {suite['ci'][1]:+.2f}]  over {suite['cases']} case(s), clustered bootstrap")
    else:
        print("\n  SUITE  no cases with both arms (ablation none?) - delta n/a")
    print()


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("files", nargs="+", help="aggregate-result.json paths")
    ap.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    ap.add_argument("--merge", action="store_true", help="pool runs of same-named cases across files")
    ap.add_argument("--k", type=int, default=3, help="k for pass^k (default 3)")
    ap.add_argument("--resamples", type=int, default=10000, help="bootstrap resamples (default 10000)")
    ap.add_argument("--seed", type=int, default=0, help="RNG seed (default 0)")
    ap.add_argument("--keep-errors", action="store_true", help="keep runs whose `error` is set")
    args = ap.parse_args(argv)

    out = []
    for label, cases in collect(args.files, args.merge, args.keep_errors):
        rng = random.Random(args.seed)
        results = [analyze_case(n, e, rng, args.resamples, args.k) for n, e in cases.items()]
        suite = suite_delta(cases, rng, args.resamples)
        if args.json:
            out.append({"source": label, "cases": results, "suite": suite})
        else:
            print_group(label, results, suite)
    if args.json:
        json.dump(out, sys.stdout, indent=2)
        print()


if __name__ == "__main__":
    main()
