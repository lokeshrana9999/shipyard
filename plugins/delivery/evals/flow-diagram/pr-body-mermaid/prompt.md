---
max_turns: 10
allowed_tools: [Read, Skill]
tags: [flow-diagram]
---

I need a diagram for my pull request description. The change: the checkout page calls POST /orders; the order service checks stock in the inventory DB; if stock is short it returns 409, otherwise it saves the order and returns 201.
