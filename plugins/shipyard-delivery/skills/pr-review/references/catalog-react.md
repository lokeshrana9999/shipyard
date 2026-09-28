# React and frontend concerns

Load when the diff touches React components, hooks, client-side data fetching, or styling.
load-when: `**/*.jsx`, `**/*.tsx`, `**/*.css`, `**/*.scss`, `**/*.less`, `**/components/**`, `**/hooks/**`, `package.json contains "react"`

## Correctness

- **Query key missing its parameters** (`correctness/query-key-missing-param`, default bug): A cache key for an id-scoped or search query that omits the id or search term serves one entity's cached data for another.
  - look-for: query-key factories or inline keys that do not include every variable the fetch depends on.
  - triggers: `queryKey`, `Key`, `useQuery(`, `useInfiniteQuery(`, `useSuspenseQuery(`, `useSWR(`

- **Mutation invalidates too little** (`correctness/incomplete-invalidation`, default issue): After a mutation, every cached query it affects (lists, counts, summaries, detail views) must be invalidated, or parts of the UI keep showing stale data.
  - look-for: a mutation success handler invalidating one key while related count or detail queries exist.
  - triggers: `invalidate`, `useMutation`, `onSuccess`, `mutate`, `refetch`, `setQueryData`, `revalidate`

- **Silenced hook dependencies** (`correctness/stale-hook-deps`, default issue): Removing a dependency to quiet the exhaustive-deps warning, or leaving a pre-refactor function in the list, makes effects run with stale values. Fix the dependency, do not suppress it.
  - look-for: a disable comment for exhaustive-deps; deps arrays that reference a renamed or wrapped function.
  - triggers: `exhaustive-deps`, `useEffect(`, `useLayoutEffect(`, `useCallback(`, `useMemo(`, `}, [`

- **Server data copied into local state** (`correctness/duplicated-server-state`, default issue): Copying fetched data or props into `useState` creates a second source of truth that drifts after refetches. Use the data directly and derive values from it.
  - look-for: `useState(data)` or an effect that sets state from query results or props.
  - triggers: `useState`, `useEffect`, `data)`, `props.`

- **Duplicate element ids across instances** (`correctness/duplicate-dom-id`, default bug): Inline SVGs or components with hardcoded internal ids (clip paths, gradients, label targets) collide when rendered more than once, causing wrong rendering or broken accessibility links. Generate per-instance ids.
  - look-for: static `id=` values referenced via `url(#...)` or `htmlFor` inside a reusable component.
  - triggers: `id=`, `url(#`, `htmlFor`, `aria-labelledby`, `aria-describedby`, `clipPath`, `Gradient`

- **Unbounded auth redirect** (`correctness/redirect-loop`, default bug): An effect that redirects based on auth or membership state can loop forever on first login or break on refresh if its condition is not terminating and refresh-safe.
  - look-for: a redirect inside an effect keyed on auth state with no guard for the destination or loading state.
  - triggers: `navigate(`, `Navigate`, `redirect`, `router.push`, `router.replace`, `location.href`, `location.assign`, `location.replace`

## Architecture

- **Reimplemented shared component** (`architecture/reimplemented-ui-primitive`, default issue): Building a local version of a button, layout, or text component that the shared library already provides, or using raw elements where the project uses primitives, splits styling and behavior. Extend the shared component instead; if a wrapper needs many pass-through props, use the shared component directly.
  - look-for: new components closely resembling existing shared ones; raw `div`/`span` where the codebase uses layout primitives.
  - triggers: `<div`, `<span`, `<button`, `<a `, `<input`, `<p`, `<h`, `export function`, `export const`, `export default`

- **Hardcoded style values** (`architecture/hardcoded-style`, default issue): Raw colors, pixel sizes, and ad hoc font sizes bypass the design tokens, break theming (such as dark mode), and drift from the design system.
  - look-for: hex, `rgb()`, or named colors and px literals in components or stylesheets where tokens exist; icons with a hardcoded fill.
  - triggers: `#`, `rgb(`, `rgba(`, `hsl(`, `px`, `fill=`, `fill:`, `color:`, `color=`, `Color`, `fontSize`, `font-size`

- **Component accreting responsibilities** (`architecture/growing-component`, default issue): Adding new API calls and handlers to an already large component makes it harder to test and review. Move the new feature into its own component or hook.
  - look-for: a large component file gaining a new request, mutation, or dialog.
  - triggers: `useQuery`, `useMutation`, `fetch(`, `axios`, `Dialog`, `Modal`, `mutate`

## Style

- **Needless memoization** (`style/needless-memo`, default nit): Wrapping cheap derivations in `useMemo` or thin setters in `useCallback` adds noise without a measurable benefit.
  - look-for: `useMemo` around a boolean or simple expression; `useCallback` around a one-line setter not passed to a memoized child.
  - triggers: `useMemo`, `useCallback`
  - gate: skip when the value is a dependency of an effect or passed to a memoized component.

- **State used for non-rendered values** (`style/state-for-ref`, default nit): Values read imperatively and never rendered (scroll positions, timers, previous values) belong in a ref; state triggers needless re-renders.
  - look-for: `useState` for values only read in handlers or effects.
  - triggers: `useState`
