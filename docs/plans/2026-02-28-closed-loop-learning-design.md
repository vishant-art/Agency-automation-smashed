# Closed-Loop Learning System Design

**Date:** 2026-02-28
**Goal:** Transform the agency's learning system from broadcast-only to a closed feedback loop where every project makes the next one smarter.

## Problem

Current state: 4 workflows write to System_Learnings, 6 read from it. But learnings are generic (not brand-specific), confidence never updates, and there's no negative feedback. The system broadcasts the same 15-20 learnings to every workflow regardless of context.

## Design

### 1. System_Learnings Table — New Fields

| Field | Type | Purpose |
|---|---|---|
| `brand_name` | Text | Which brand this learning applies to (empty = agency-wide) |
| `industry` | Text | Industry tag for cross-brand relevance |
| `concept_id` | Text | Links back to the concept that generated this insight |
| `script_id` | Text | Links back to the script that proved it |
| `times_confirmed` | Number | How many times this pattern has been validated by performance data |
| `last_confirmed_at` | DateTime | When it was last confirmed — drives recency weighting |
| `decay_score` | Number | 0-10, starts at confidence value, decays over time if not confirmed |

### 2. Performance Sync — Brand-Specific Write-Back

- Tag every learning with `brand_name` and `industry` from matched script/project
- Link `script_id` and `concept_id` (trace script -> concept via Airtable lookup)
- Write two types per sync:
  - **Brand-specific**: "Wheelwash POV hooks got 3.2x ROAS vs 1.4x for testimonials"
  - **Agency-wide**: "Across D2C brands, POV hooks outperform testimonials by 2.3x" (only when pattern appears across 2+ brands)
- When a learning matches an existing one (same pattern, same brand): bump `times_confirmed` and update `last_confirmed_at` instead of creating a duplicate

### 3. Phase 1 & Script Agent — Layered Learning Fetch

Replace single fetch with two fetches:
1. **Brand-specific** (max 10): `AND({active}=TRUE(), {brand_name}='BrandName')` sorted by `decay_score` DESC
2. **Agency-wide** (max 10): `AND({active}=TRUE(), {brand_name}='')` sorted by `decay_score` DESC

Inject into prompt with clear hierarchy:
```
== LEARNINGS FROM THIS BRAND (highest priority) ==
[1] (hook_patterns, confirmed 4x, decay: 9.2) POV hooks got 3.2x ROAS...

== AGENCY-WIDE LEARNINGS ==
[1] (script_quality, confirmed 12x, decay: 8.7) Scripts with self-corrections...
```

### 4. Orchestrator v2 — Learning Curation Pass

New branch after event processing:
- **Decay**: -0.1 decay_score per week since `last_confirmed_at`. Below 3.0 = retire (active=false)
- **Merge**: >70% word similarity + same brand = merge (keep higher confidence, sum times_confirmed)
- **Promote**: Brand-specific learning appearing across 3+ brands = create agency-wide version
- **Negative feedback**: Underperformer script linked to a learning = reduce decay_score by 1.0

### 5. Concept -> Script -> Ad Tracking

- Phase 3/Script Agent writes `concept_id` onto each script record
- Performance Sync traces script -> concept -> learning (full circle)

## Workflows Modified

1. **Performance Sync** (`DZbFqt2WtxlXtXl1`) — Brand tagging, concept linking, confirmation bumping
2. **Phase 1** (`RLi-u9gL1aQ7Bl37TSidA`) — Layered learning fetch (brand + agency)
3. **Script Agent** (`XNdHsZnLclh1pARm`) — Layered learning fetch + concept_id write-through
4. **Phase 3** (`iZOxbVl1X2w74Pzi`) — Layered learning fetch + concept_id write-through
5. **Orchestrator v2** (`DUfrRerxOinES9Cf`) — Learning curation pass (decay, merge, promote, retire)

## Data Flow

```
Concepts (Phase 1) -> Scripts (Phase 3/Agent) -> Ads (Meta) -> Performance Sync
     ^                                                              |
     |                                              Brand-specific learnings
     |                                                     |
     <------- Phase 1 reads brand + agency learnings <------
                                                           |
                                          Orchestrator curates: decay, merge, promote, retire
```
