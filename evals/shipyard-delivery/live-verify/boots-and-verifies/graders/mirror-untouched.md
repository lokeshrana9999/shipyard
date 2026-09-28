---
type: regex
target: { source: file, path: data/mirror.json }
pattern: '^\{"users":\["alice@example\.test","bob@example\.test"\],"nextId":3,"notes":\[\{"id":1,"owner":"alice@example\.test","text":"alice''s first note","archived":false,"archivedAt":null,"version":1\},\{"id":2,"owner":"bob@example\.test","text":"staging sync marker","archived":false,"archivedAt":null,"version":4\}\]\}\s*$'
---
