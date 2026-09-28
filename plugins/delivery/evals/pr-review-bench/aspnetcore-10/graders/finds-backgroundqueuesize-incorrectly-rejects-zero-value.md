---
# Bench issue: BackgroundQueueSize incorrectly rejects zero value despite 'non-negative' contract (src/Logging.AzureAppServices/src/BatchingLoggerOptions.cs:42-53); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*src[\\/]+BatchingLoggerOptions\.cs")(?=[^{}]*"line"\s*:\s*"?(?:37|38|39|40|41|42|43|44|45|46|47|48|49|50|51|52|53|54|55|56|57|58)(?![0-9]))[^{}]*\}'
flags: i
---
