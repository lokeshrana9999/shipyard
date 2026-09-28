---
# Bench issue: RetainedFileCountLimit allows zero value violating positive-only constraint (src/Logging.AzureAppServices/src/AzureFileLoggerOptions.cs:48-59); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*src[\\/]+AzureFileLoggerOptions\.cs")(?=[^{}]*"line"\s*:\s*"?(?:43|44|45|46|47|48|49|50|51|52|53|54|55|56|57|58|59|60|61|62|63|64)(?![0-9]))[^{}]*\}'
flags: i
---
