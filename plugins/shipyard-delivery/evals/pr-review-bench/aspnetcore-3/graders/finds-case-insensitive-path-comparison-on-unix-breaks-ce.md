---
# Bench issue: Case-insensitive path comparison on Unix breaks certificate directory detection (src/Shared/CertificateGeneration/UnixCertificateManager.cs:373-376); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*CertificateGeneration[\\/]+UnixCertificateManager\.cs")(?=[^{}]*"line"\s*:\s*"?(?:368|369|370|371|372|373|374|375|376|377|378|379|380|381)(?![0-9]))[^{}]*\}'
flags: i
---
