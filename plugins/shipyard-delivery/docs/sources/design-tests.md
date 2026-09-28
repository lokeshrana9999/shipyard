# Sources: design-tests

Provenance for the rules in `skills/design-tests/`. Kept outside the skill folder so it never loads into context.

## Expectations from the spec, not the code
- LLM oracles assert actual rather than expected behavior (Konstantinou, Degiovanni, Papadakis 2024): https://arxiv.org/abs/2410.21136
- Requirement-derived assertions match requirements over buggy code (Ma & Eisty 2026, pilot): https://arxiv.org/abs/2607.10277
- Self-repair drifts toward weaker assertions (Li, Yu, Yuan, ASE 2026): https://arxiv.org/abs/2608.05917
- Oracle evidence should be stated (Mughal & Bilal, IEEE Access 2026 review): https://arxiv.org/abs/2607.05031

## Assertion strength
- ChatTester: hallucinated APIs and wrong assertions (Yuan et al., FSE 2024): https://dl.acm.org/doi/10.1145/3660783
- Weak assertions and mutation feedback (MutGen 2025): https://arxiv.org/abs/2506.02954
- Coverage and mutation score unreliable when code is buggy (Zhao, Zhou, Cohen, ISSTA 2026): https://arxiv.org/abs/2607.22880

## Techniques and categories
- Boundary value analysis finds the most faults (Reid 1997): https://ieeexplore.ieee.org/document/637166/
- Most failures involve one or two parameters (NIST, Kuhn et al.): https://csrc.nist.gov/projects/automated-combinatorial-testing-for-software/combinatorial-methods-in-testing/interactions-involved-in-software-failures
- Mishandled error paths cause most catastrophic failures (Yuan et al., OSDI 2014): https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf
- Date and time bugs, time zones (Tiwari et al., MSR 2025): https://rohan.padhye.org/files/datetimebugs-msr25.pdf
- Property-based testing effectiveness (Ravi & Coblenz, OOPSLA 2025): https://dl.acm.org/doi/10.1145/3764068
- ISTQB CTFL v4.0 techniques: https://www.istqb.com/ctfl-v4-0/
- ISO/IEC/IEEE 29119-3 and -4 (traceability, coverage items): https://www.iso.org/standard/79429.html

## Layers and mocking
- No significant defect-detection difference between unit and integration tests (Trautsch, Herbold, Grabowski, JSS 2020): https://www.swe.informatik.uni-goettingen.de/sites/default/files/publications/main2_0.pdf
- Mocks drift from real behavior (Spadini et al., MSR 2017): https://sback.it/publications/msr2017b.pdf
- Agents over-mock (Hora & Robbes, MSR 2026): https://arxiv.org/abs/2602.00409

## API coverage
- OWASP API Security Top 10 (2023): https://owasp.org/API-Security/editions/2023/en/0x11-t10/
- BOLA state-changing cases dominate (Kaur 2026): https://arxiv.org/abs/2605.25865
- Schemathesis checks: https://schemathesis.readthedocs.io/en/stable/reference/checks/

## Scenario style
- Declarative Gherkin: https://cucumber.io/docs/bdd/better-gherkin/
- Playwright test agents (plan-then-generate, seed test): https://playwright.dev/docs/test-agents

## Specifics removed from the skill (as of 2026-09-27)

- API table rows were tagged with OWASP API Security Top 10 (2023) IDs: API1 object-level authorization (another user's or tenant's resource), API2 broken authentication (no, expired, or malformed token), API3 object property-level authorization (mass-assignable fields, extra response fields), API4 unrestricted resource consumption (oversized body or page size), API5 function-level authorization (caller without the required role). The doc-template example rows used API1 and API3.
- SKILL.md handoff: the implement stage is "a later shipyard skill; until it exists, whoever writes the tests".
