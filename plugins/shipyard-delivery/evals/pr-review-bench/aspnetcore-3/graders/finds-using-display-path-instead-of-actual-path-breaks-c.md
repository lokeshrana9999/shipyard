---
# Bench issue: Using display path instead of actual path breaks certificate directory validation (src/Shared/CertificateGeneration/UnixCertificateManager.cs:364-365); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*CertificateGeneration[\\/]+UnixCertificateManager\.cs")(?=[^{}]*"line"\s*:\s*"?(?:359|360|361|362|363|364|365|366|367|368|369|370)(?![0-9]))[^{}]*\}'
flags: i
---
