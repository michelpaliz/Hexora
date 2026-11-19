# Statements AI match scoring audit

Status: **open backend/contract work** (UI refactor complete, matching logic untouched).

Scope: the `POST /entries/{entryId}/ai-match-suggestions` response consumed by
`StatementsAiMatchSuggestDialog` and the insights reconciliation dialog. This
audit records inconsistencies observed in the data contract and in how the
front-end presented them. No scoring, ranking, tolerance or accounting rule was
changed by the UI refactor.

## Fields involved

| Field | Meaning in the front-end |
| --- | --- |
| `result.aiUsed` | Chooses the "IA" vs "Heurística" badge. |
| `result.reviewRequired` | Shows the "Revisión manual" badge. Missing is treated as `true`. |
| `suggestion.rank` | Displayed as `#rank`; also the primary display sort key. |
| `suggestion.score` | Heuristic score, displayed as `Coincidencia NN%`. |
| `suggestion.ai.confidence` | AI confidence, displayed as `IA NN%`. |
| `suggestion.reasons` / `suggestion.ai.flags` | Inline evidence and "Motivos" pills. |
| `suggestion.alreadyLinkedCount` / `document.alreadyLinked*` | Duplicate warnings. |
| `suggestion.totalAmount` / `suggestion.amountDelta` | Amount validation against `targetAmount`. |

The dialog normalises ratios in one place (`_ratio`, 0..1 or 0..100 accepted)
and keeps the backend values otherwise verbatim.

## Findings

### 1. Two different confidence scales are shown side by side

`score` and `ai.confidence` are independent metrics: a heuristic score and an
LLM self-assessment. They can legitimately differ, but the previous UI showed
only `Score NN%` in the card and the AI confidence inside the explanation box,
which made the numbers look like duplicates. The new UI shows both
(`Coincidencia NN%`, `IA NN%`) and flags a divergence of >= 15 points with
`Confianza divergente` plus a tooltip. This is **flagging only**: the algorithm
and the ordering are unchanged.

Related code:
- `statements_ai_match_suggest_dialog.dart` – `_ratio`, `_hasConfidenceConflict`,
  `_confidenceConflictText`.
- `insights_bank_income_parsing.dart` – `bankIncomeMatchConfidence` reads
  `matchConfidenceLabel`, a different vocabulary from `score` + `ai.confidence`.

Recommendation: expose one documented confidence contract. Either
`score` + `confidenceLabel` (high/medium/low) or `score` + `ai.confidence`,
but not both unlabelled numeric percentages across surfaces.

### 2. `ai.confidence` can outlive `aiUsed == false`

The dialog reads `suggestion.ai.confidence` without checking `result.aiUsed`.
If the backend returns heuristic suggestions with a stale `ai` object, the UI
will render an "IA NN%" badge even though the header says "Heurística".

Recommendation: return `ai` only when `aiUsed == true`, or add
`ai.applied: bool` and gate the badge on it.

### 3. Rank order need not match score order

`_orderedSuggestions` sorts by `rank` first (backend order) and only falls back
to `score` when ranks are absent. If a response contains rank `#1` with 72%
and rank `#2` with 91%, the UI still calls `#1` the best match. This is the
intended "trust backend order" behaviour, but it should be an explicit
contract: rank is the ranking, score is evidence.

Recommendation: document that `rank` is 1-based and authoritative; or stop
sending rank and let the client sort by score.

### 4. Score range is implicit

`_ratio` treats numbers above 1.5 as percentages and clamps to 0..1. A score
of `1.0` is read as 100%, and `1.5` as 100% too. The contract does not state
whether scores are 0..1 or 0..100.

Recommendation: fix the range in the API (0..1 is the safer convention) and
stop sending pre-formatted percentages in numeric fields.

### 5. `amountDelta` and `totalAmount - targetAmount` can disagree

The confirmation panel prefers `amountDelta` and falls back to
`totalAmount - targetAmount`. If the backend explicitly sends `amountDelta`,
the client does not verify it. A stale delta could therefore show "no
difference" while the two amounts differ.

Recommendation: return `amountDelta` always, computed server-side from the
same values used for the tolerance check, and document the tolerance (5% in
the current request).

### 6. Duplicate flags are split across two levels

`alreadyLinkedCount` lives on the suggestion, while `alreadyLinked`,
`linkedEntriesCount` and `linkedEntryId` live on each document. The dialog
treats any of them as a duplicate. The old dialog only looked at
`alreadyLinkedCount` on the suggestion. A document-level flag without a
suggestion-level count was silently lost.

Recommendation: expose a single `alreadyLinked` boolean and
`linkedEntriesCount` on both levels, or return only the suggestion aggregate.

### 7. `reviewRequired` defaults to `true` when absent

`result.reviewRequired != false` means a missing field shows "Revisión manual".
This is conservative but hides the difference between "backend says review"
and "backend did not send the field".

Recommendation: always send `reviewRequired`; the client can then use
`== true`.

### 8. Combination scores are not decomposable per document

For `matchType == "combination"` the score applies to the whole combination.
Documents do not carry their own score, so the UI cannot explain which
document contributed what. The combined match is still presented as one
suggestion with a document list, which is correct, but the "best match" label
can be read as a per-document claim.

Recommendation: add `matchType` to the contract documentation and, if
possible, per-document `contribution` values for the explanation panel.

### 9. Two reconciliation surfaces use different confidence vocabularies

The statements dialog uses `score` + `ai.confidence`; the insights chat
dialog uses `matchScorePercent` + `matchConfidenceLabel`
(`insights_bank_income_parsing.dart`). The same invoice/entry pair can
therefore show a different confidence label depending on where it is opened.

Recommendation: share one response mapper or one confidence enum between
both surfaces.

## What the UI refactor does about it

- Displays both percentages and flags divergence instead of hiding one.
- Does not modify `score`, `rank`, `ai`, `totalAmount`, `amountDelta`,
  `reasons`, `reviewRequired`, `apply` or any request parameter.
- Warns (does not block) on amount mismatch, duplicate links and low
  heuristic confidence before the confirmation step.
- Keeps `method: 'auto'`, `tolerance: 0.05`, `maxWindowDays: 180`,
  `maxCombinationSize: 3`, `limit: 12`, `includeLinked: true` unchanged.

## Out of scope

- Changing the matching/ranking algorithm.
- Changing link/accounting persistence.
- Deciding the canonical confidence scale. That is a backend contract task.
