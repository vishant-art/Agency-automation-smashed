# Airtable Scripts & Concepts Tables Schema

## Scripts Table (tbl2D9mapezLKMPg7)

**Purpose**: Store generated UGC scripts for client projects
**Records**: 24 total
**Status**: 17/36 fields currently unused

### All Fields

#### Linking & Reference Fields
- `project_id` (Link to Projects) - Required. Links script to project
- `concept_id` (Link to Concepts) - Required. Links script to approved concept

#### Script Structure Fields (AIDA Model Components)
- `hook` - Opening hook to grab attention (seconds 0-3)
- `hook_1` - First hook variation
- `hook_2` - Second hook variation  
- `hook_3` - Third hook variation
- `hook_reinforcement` - Secondary hook to maintain attention
- `problem` - Problem statement in the story
- `solution` - The solution being presented
- `proof` - Evidence/proof of the solution (testimonials, results)
- `cta` - Call-to-action statement

#### Full Content
- `full_script` - Complete script text (formatted for reading)

#### Production Guidance
- `visual_direction` - How the video should look and feel
- `on_screen_text` - Text overlays to display
- `creator_notes` - Special instructions for the creator
- `estimated_duration` - Expected video length
- `thumbnail_frame` - Frame number for thumbnail/preview
- `costumes` - Clothing/costume requirements
- `props` - Props needed
- `creative_table_json` - Detailed creative specifications as JSON object

#### Context & Planning
- `concept_story` - The narrative/story arc being used
- `script_number` - Sequential number for this script

#### Quality & Review
- `qa_score` - Quality assurance score (numeric)
- `version` - Version number (defaults to 1, increments on revision)

#### Status Tracking
- `pm_status` - Internal PM status: "Pending" | "Approved" | "Rejected" | "In Review"
- `client_status` - Client-visible status: "Pending" | "Approved" | "Revision" | "Delivered"
- `overall_status` - Combined status: "PM Review" | "Client Review" | "Delivered" | "Archived"

### Total Fields: 26 implemented, 10 reserved for future use

---

## Concepts Table (tbl4pDNYswMN2Fx6X)

**Purpose**: Store content concepts/ideas that scripts are based on
**Records**: 16 total
**Status**: Core fields only (~10 active fields)

### All Fields (Inferred from Phase 1 & Phase 2 Operations)

#### Linking & Reference Fields
- `project_id` (Link to Projects) - Required. Links concept to project
- `reference_videos` (Link to Reference_Videos) - Array of reference video links

#### Concept Definition
- `concept_title` - Title/name of the concept
- `concept_description` - Detailed description
- `brand_voice` - How it aligns with brand voice
- `key_messages` - Main messages to communicate
- `target_audience` - Who this is intended for
- `content_pillars` - Content category (e.g., "Education", "Entertainment", "Lifestyle")

#### Strategy & Validation
- `competitor_reference` - References to competitive/benchmark concepts
- `approval_status` - Status: "Pending" | "Approved" | "Rejected"
- `approved_by` - Name of approver
- `approval_date` - When it was approved

#### Feedback & Iteration
- `revision_feedback` - Notes for concept revision
- `exclusion_list` - Themes/concepts to avoid in regeneration

#### Metadata
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp
- `client_status` - Client-visible status (referenced in filterByFormula)

### Total Fields: ~15 implemented

---

## Field Type Details

### Scripts Table Field Types (from API call)
```javascript
{
  // Linked Fields (array format required for Airtable API)
  "project_id": ["recXXXXXXXXXXXXXX"],      // Array of IDs
  "concept_id": ["recYYYYYYYYYYYYYY"],      // Array of IDs
  
  // Text & Numeric
  "script_number": 1,                       // Number
  "hook": "Opening statement...",           // Text
  "hook_1": "Alt hook 1...",                // Text
  "hook_2": "Alt hook 2...",                // Text
  "hook_3": "Alt hook 3...",                // Text
  "hook_reinforcement": "Secondary...",     // Text
  "problem": "The problem is...",           // Text
  "solution": "The solution is...",         // Text
  "proof": "Evidence that...",              // Text
  "cta": "Click below now!",                // Text
  "full_script": "Complete script...",      // Long Text
  "visual_direction": "Shot list...",       // Text
  "on_screen_text": "Overlay text",         // Text
  "creator_notes": "Remember to...",        // Text
  "estimated_duration": "60s",              // Text
  "thumbnail_frame": "0:15",                // Text
  "costumes": "Black shirt",                // Text
  "props": "Coffee cup",                    // Text
  "creative_table_json": "{}",              // Text (JSON string)
  "concept_story": "The arc is...",         // Text
  "qa_score": 9.2,                          // Number
  "version": 1,                             // Number
  
  // Select Fields
  "pm_status": "Pending",                   // Single Select
  "client_status": "Pending",               // Single Select
  "overall_status": "PM Review"             // Single Select
}
```

### Concepts Table Field Types (inferred)
```javascript
{
  // Linked Fields
  "project_id": ["recXXXXXXXXXXXXXX"],      // Array of IDs
  "reference_videos": ["recVVVVVVVVVVVVVV"], // Array of IDs
  
  // Text Fields
  "concept_title": "Concept name",
  "concept_description": "Full description",
  "brand_voice": "How it aligns",
  "key_messages": "Main points",
  "target_audience": "Target demo",
  "content_pillars": "Category",
  "competitor_reference": "Benchmarks",
  "revision_feedback": "Notes",
  "exclusion_list": "Avoid these",
  
  // Select Field
  "approval_status": "Pending",             // Single Select
  
  // Other
  "approved_by": "Person name",             // Text
  "approval_date": "2026-02-25",            // Date
  "created_at": "2026-02-20T10:00:00",      // DateTime
  "updated_at": "2026-02-25T15:30:00",      // DateTime
  "client_status": "Pending"                // Single Select (used in filters)
}
```

---

## API Integration Pattern

### Scripts Table - Create/Batch Create
```json
POST /v0/appvFxwZc9yU8o8pK/Scripts
{
  "records": [
    {
      "fields": {
        "project_id": ["recXXX"],
        "concept_id": ["recYYY"],
        "script_number": 1,
        "hook": "...",
        // ... other fields
        "pm_status": "Pending",
        "client_status": "Pending",
        "overall_status": "PM Review"
      }
    }
  ]
}
```

### Concepts Table - Query Filter Pattern
```
filterByFormula=AND(
  FIND('client_code', ARRAYJOIN({project_id})) > 0,
  {client_status} = 'Approved'
)
```

---

## Critical Implementation Notes for Content Repurposing Workflow

1. **Linked Fields Format**: When storing, use array format: `["recID"]` not `"recID"`
2. **Batch Operations**: Use batch create API (10 records/request) for bulk operations
3. **Rate Limiting**: 5 req/sec limit - use `batchInterval: 300ms` between batch operations
4. **Select Options**: Token needs `schema.bases:write` to create new select values
5. **Google Docs Integration**: `google_doc_id` field referenced in Phase 4 for comment access (not in current schema - may need to add)


---

## Quick Field Reference (Copy-Paste Ready)

### All Scripts Fields (26 total)
```
project_id, concept_id, script_number, hook, hook_1, hook_2, hook_3, 
hook_reinforcement, problem, solution, proof, cta, full_script, 
visual_direction, on_screen_text, creator_notes, estimated_duration, 
thumbnail_frame, costumes, props, creative_table_json, concept_story, 
qa_score, version, pm_status, client_status, overall_status
```

### All Concepts Fields (17 total)
```
project_id, reference_videos, concept_title, concept_description, 
brand_voice, key_messages, target_audience, content_pillars, 
competitor_reference, approval_status, approved_by, approval_date, 
revision_feedback, exclusion_list, created_at, updated_at, client_status
```

---

## For Building Content Repurposing Workflow

The Scripts table fields that are most relevant for repurposing:

1. **Source Content** (What to repurpose from):
   - `full_script` - The complete script text
   - `hook` / `hook_1` / `hook_2` / `hook_3` - Hook variations
   - `visual_direction` - Visual style guidance
   - `concept_story` - Narrative framework
   - `creative_table_json` - Detailed creative specs

2. **Metadata for Tracking**:
   - `script_number` - Track which script in the series
   - `version` - Current version (increment on repurposing)
   - `qa_score` - Quality baseline
   - `estimated_duration` - Original length

3. **Repurposing Output Storage** (New fields to consider adding):
   - `repurposing_formats` - List of formats created (TikTok, Reel, YouTube Short, etc.)
   - `repurposing_versions` - JSON array of repurposed script variants
   - `repurposing_status` - Track repurposing completion state
   - `repurposing_date` - When repurposing was completed

4. **Status Tracking**:
   - `overall_status` - Update to reflect repurposing phase
   - `pm_status` - Track internal approval of repurposed versions

---

## Example Workflow Logic

```
1. Query Scripts table for:
   - overall_status = "Delivered" (scripts that are finalized)
   - version >= 1 (any version)
   
2. For each script, extract:
   - full_script
   - visual_direction
   - hook + variations
   - on_screen_text
   - estimated_duration
   
3. Pass to repurposing engine (Gemini/GPT-4)
   
4. Create repurposed variants for:
   - TikTok (15-60 sec, high hooks)
   - Instagram Reel (15-60 sec, different pacing)
   - YouTube Short (15-60 sec, optimized for discovery)
   - LinkedIn (professional angle)
   - Twitter/X (text-first with emoji)
   
5. Store results:
   - Create new records OR append to repurposing_versions field
   - Set overall_status = "Repurposing Complete"
   - Increment version number
   - Log repurposing_date
```

---

**Generated**: 2026-02-25
**Source**: Phase 3 Workflow HTTP Request node analysis
**Last Updated**: Analysis of actual n8n workflow implementations

