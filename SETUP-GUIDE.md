# Smashed Agency — UGC Script Agent System: Complete Setup Guide

> **5 workflows, 4 AI agents, Airtable database, multi-stage approval gates.**
> Estimated setup time: 45-60 minutes.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Airtable Database Setup](#2-airtable-database-setup)
3. [n8n Installation & Import](#3-n8n-installation--import)
4. [Credential Setup](#4-credential-setup)
5. [Webhook URL Configuration](#5-webhook-url-configuration)
6. [Google Sheets Template](#6-google-sheets-template)
7. [Tally Onboarding Form](#7-tally-onboarding-form)
8. [Slack Configuration](#8-slack-configuration)
9. [Testing & Validation](#9-testing--validation)
10. [Cost Breakdown](#10-cost-breakdown)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Prerequisites

### Accounts Needed (all have free tiers)

| Service | Purpose | Sign Up |
|---------|---------|---------|
| n8n | Workflow engine | Self-host (free) or n8n.io cloud ($20/mo) |
| OpenAI | GPT-4o + GPT-4o-mini for AI agents | platform.openai.com |
| SerpAPI | Google/Reddit/Amazon/TikTok searches | serpapi.com (100 free searches/mo) |
| Airtable | Central database | airtable.com (free: 1,000 records/base) |
| Google | Sheets + Drive + Docs | accounts.google.com |
| Slack | Notifications + approval buttons | slack.com |
| ClickUp | Task management (optional) | clickup.com |
| Tally | Client onboarding form | tally.so |

---

## 2. Airtable Database Setup

### Create a new Airtable Base called "UGC Script Engine"

You need **5 tables**. Create them in this exact order (linked fields depend on earlier tables existing).

---

### Table 1: Projects

| Field Name | Field Type | Options/Notes |
|------------|-----------|---------------|
| project_id | Auto Number | Primary field — auto-generates |
| client_code | Single line text | e.g., "GLO-0214" |
| brand_name | Single line text | e.g., "GlowSkin" |
| client_name | Single line text | |
| client_email | Email | |
| website_url | URL | |
| num_scripts | Number (integer) | How many scripts ordered |
| brief_summary | Long text | Auto-populated summary |
| status | Single select | Options: `Research`, `Concepts Pending`, `PM Review`, `Client Review`, `Scripting`, `Script Review`, `Delivered`, `On Hold` |
| created_at | Created time | Auto-set |
| updated_at | Last modified time | Auto-set |
| google_sheet_row | Single line text | Reference back to Sheets |

**Set the "status" field default to "Research".**

---

### Table 2: Research

| Field Name | Field Type | Options/Notes |
|------------|-----------|---------------|
| research_id | Auto Number | Primary field |
| project_id | Link to another record | Link to **Projects** table |
| research_type | Single select | Options: `VOC Quote`, `Competitor Intel`, `Market Trend`, `Audience Insight`, `Script Ammunition`, `Brand Analysis` |
| source | Single select | Options: `Amazon`, `Reddit`, `Forum`, `Brand Website`, `Google`, `TikTok`, `Instagram`, `Meta Ad Library`, `Trustpilot` |
| category | Single select | Options: `Pain`, `Desire`, `Proof`, `Objection`, `Language`, `Competitor Gap`, `Trend`, `Insight` |
| content | Long text | The actual quote, insight, or data point |
| relevance | Single select | Options: `High`, `Medium`, `Low` |
| source_url | URL | Link to original source |

---

### Table 3: Reference_Videos

| Field Name | Field Type | Options/Notes |
|------------|-----------|---------------|
| reference_id | Auto Number | Primary field |
| project_id | Link to another record | Link to **Projects** table |
| url | URL | Full video/ad URL |
| platform | Single select | Options: `TikTok`, `Instagram Reels`, `Facebook Ad`, `Instagram Ad`, `YouTube Shorts` |
| type | Single select | Options: `Organic Viral`, `Paid Ad`, `UGC Ad`, `Creator Content` |
| format | Single select | Options: `Talking Head`, `GRWM`, `Before-After`, `Unboxing`, `POV`, `Storytime`, `Routine`, `Transformation`, `Comparison`, `Green Screen`, `Testimonial Ad`, `Product Demo`, `Stitch/Duet` |
| hook | Single line text | First line or visual that stopped the scroll |
| why_it_works | Long text | Analysis of why this reference performs |
| adaptation_idea | Long text | How to adapt for the client's product |
| engagement | Single line text | Views, likes, or ad run duration |

---

### Table 4: Concepts

| Field Name | Field Type | Options/Notes |
|------------|-----------|---------------|
| concept_id | Auto Number | Primary field |
| project_id | Link to another record | Link to **Projects** table |
| reference_id | Link to another record | Link to **Reference_Videos** table |
| concept_name | Single line text | e.g., "The Skeptic Convert" |
| framework | Single select | Options: `PAS`, `BAB`, `AIDA`, `FAB`, `PASTOR`, `4Ps`, `Star-Story-Solution`, `Feel-Felt-Found`, `SLAP`, `Curiosity Gap`, `Contrast Frame`, `Micro-Story` |
| hook_type | Single select | Options: `Controversy`, `POV`, `Calling-Out`, `Negative`, `Authority`, `Social Proof`, `Curiosity Gap`, `Story`, `Fear/Urgency`, `Hot Take`, `Whisper/ASMR`, `Text-First` |
| hook_text | Single line text | The exact opening line |
| format | Single select | Same options as Reference_Videos format field |
| funnel_stage | Single select | Options: `TOF`, `MOF`, `BOF` |
| virality_score | Number (1-10) | Agent-assigned score |
| concept_pitch | Long text | One-line pitch for the client |
| emotional_journey | Single line text | e.g., "frustration → curiosity → relief → desire" |
| target_objection | Single line text | Which hesitation this concept kills |
| platform | Single select | Options: `TikTok`, `Instagram Reels`, `Facebook`, `YouTube Shorts`, `Multi-platform` |
| ab_test_pair | Link to another record | Link to **Concepts** table (self-referencing) |
| pm_status | Single select | Options: `Pending`, `Approved`, `Rejected`, `Revision` — **Default: Pending** |
| pm_notes | Long text | PM's feedback |
| client_status | Single select | Options: `Pending`, `Approved`, `Rejected`, `Revision` — **Default: Pending** |
| client_notes | Long text | Client's feedback |
| overall_status | Single select | Options: `Draft`, `PM Review`, `Client Review`, `Approved`, `Rejected` — **Default: Draft** |

---

### Table 5: Scripts

| Field Name | Field Type | Options/Notes |
|------------|-----------|---------------|
| script_id | Auto Number | Primary field |
| project_id | Link to another record | Link to **Projects** table |
| concept_id | Link to another record | Link to **Concepts** table |
| script_number | Number (integer) | |
| concept_name | Single line text | Copied from concept |
| hook | Long text | First 3 seconds |
| hook_reinforcement | Long text | 3-5 seconds |
| problem | Long text | 5-12 seconds |
| solution | Long text | 12-20 seconds |
| proof | Long text | 20-25 seconds |
| cta | Long text | 25-30 seconds |
| full_script | Long text | Complete creator script |
| visual_direction | Long text | Second-by-second direction |
| on_screen_text | Long text | Text overlay cues |
| creator_notes | Long text | Tone, energy, pacing, setting |
| estimated_duration | Single line text | e.g., "25 sec" |
| thumbnail_frame | Long text | First frame description |
| reference_video_url | URL | Reference that inspired this |
| reference_platform | Single select | Same as Reference_Videos platform |
| reference_type | Single select | Same as Reference_Videos type |
| framework_used | Single select | Same options as Concepts framework |
| virality_score | Number | |
| qa_score | Number | QA agent quality score |
| pm_status | Single select | Options: `Pending`, `Approved`, `Rejected`, `Revision` — **Default: Pending** |
| pm_notes | Long text | |
| client_status | Single select | Options: `Pending`, `Approved`, `Rejected` — **Default: Pending** |
| client_notes | Long text | |
| overall_status | Single select | Options: `Draft`, `QA Review`, `PM Review`, `Client Review`, `Approved`, `Delivered` — **Default: Draft** |
| version | Number (integer) | Default: 1 |

---

### Airtable Views (Recommended)

Create these filtered views for easy review:

**In the Concepts table:**
- "PM Review" view — Filter: `pm_status = Pending`, sorted by `virality_score` descending
- "Client Review" view — Filter: `pm_status = Approved` AND `client_status = Pending`
- "Approved" view — Filter: `client_status = Approved`

**In the Scripts table:**
- "PM Review" view — Filter: `pm_status = Pending`, sorted by `script_number`
- "Ready for Delivery" view — Filter: `pm_status = Approved`

**In the Projects table:**
- "Active Pipeline" view — Filter: `status != Delivered`, sorted by `created_at` descending

### Get Your Airtable IDs

After creating the base, you need two things:

1. **Base ID**: Go to https://airtable.com/developers/web/api/introduction → select your base → the URL shows `app...` — that's your Base ID
2. **Personal Access Token**: Go to https://airtable.com/create/tokens → Create token → Scopes: `data.records:read`, `data.records:write`, `schema.bases:read` → Add your base

**Replace `YOUR_AIRTABLE_BASE_ID` in all workflow files with your actual Base ID.**

---

## 3. n8n Installation & Import

### Option A: Self-Hosted (Free)

```bash
# Docker (recommended)
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v n8n_data:/home/node/.n8n \
  docker.n8n.io/n8nio/n8n

# Access at http://localhost:5678
```

### Option B: n8n Cloud ($20/mo)

Sign up at https://app.n8n.cloud

### Import Workflows

Import these 5 workflow files **in this order**:

| Order | File | Webhook Path |
|-------|------|-------------|
| 1 | `n8n-ugc-onboarding-workflow.json` | `/webhook/ugc-onboarding` |
| 2 | `n8n-workflow-1-research-concepts.json` | `/webhook/ugc-phase1` |
| 3 | `n8n-workflow-2-concept-approval.json` | `/webhook/ugc-concept-approval` |
| 4 | `n8n-workflow-3-script-writing.json` | `/webhook/ugc-phase3` |
| 5 | `n8n-workflow-4-delivery.json` | `/webhook/ugc-delivery` |

**To import:** In n8n, go to Workflows → Import from File → select the JSON file.

---

## 4. Credential Setup

After importing, you need to set up credentials in n8n. Go to **Settings → Credentials** and create:

### 4.1 OpenAI API Key

- **Name**: `OpenAI account`
- **Type**: OpenAI API
- **API Key**: Your OpenAI API key from https://platform.openai.com/api-keys

**Used by**: Workflow 1 (Research Agent, Strategy Agent), Workflow 3 (Writer Agent, QA Agent)

### 4.2 SerpAPI Key

- **Name**: `SerpAPI Key`
- **Type**: Header Auth
- **Header Name**: `Authorization` (but note: SerpAPI uses query param, not header — the key is embedded in the URL)
- **Value**: Your SerpAPI key from https://serpapi.com/manage-api-key

**Used by**: Workflow 1 (Google Search, Reddit, Amazon, TikTok, Instagram, Meta Ad Library, Competitor Ad tools)

> **Important**: SerpAPI free tier = 100 searches/month. Each client run uses ~10-15 searches. Budget for ~7-10 clients/month on free tier.

### 4.3 Airtable Personal Access Token

- **Name**: `Airtable Personal Access Token`
- **Type**: Airtable Personal Access Token
- **Token**: From https://airtable.com/create/tokens

**Used by**: All 4 main workflows (read/write to all 5 tables)

### 4.4 Google Sheets OAuth2

- **Name**: `Google Sheets account`
- **Type**: Google Sheets OAuth2
- Follow n8n's Google OAuth2 setup guide

**Used by**: Onboarding workflow, Workflow 1 (fetch brief), Workflow 3 (fetch brief), logging

### 4.5 Google Drive OAuth2

- **Name**: `Google Drive account`
- **Type**: Google Drive OAuth2
- Same OAuth2 credentials as Google Sheets

**Used by**: Workflow 4 (write to Google Docs)

### 4.6 Slack OAuth2

- **Name**: `Slack account`
- **Type**: Slack OAuth2
- Create a Slack App at https://api.slack.com/apps
- Bot scopes needed: `chat:write`, `chat:write.public`, `channels:read`

**Used by**: All workflows (notifications + approval buttons)

### 4.7 ClickUp API (Optional)

- **Name**: `ClickUp API`
- **Type**: ClickUp API
- API key from: ClickUp → Settings → Apps → API Token

**Used by**: Workflow 4 (update task cards)

---

## 5. Webhook URL Configuration

The workflows chain together via webhooks. After importing and activating, you need to update the URLs.

### Find Your n8n Base URL

- **Self-hosted**: `http://your-server:5678` or your domain
- **n8n Cloud**: `https://your-instance.app.n8n.cloud`

### URLs to Update

**In Workflow 1** (n8n-workflow-1-research-concepts.json):
- No external webhook URLs needed (this is triggered externally)

**In Workflow 2** (n8n-workflow-2-concept-approval.json):
- The Slack buttons in Workflow 1 contain `YOUR_N8N_BASE_URL/webhook/ugc-concept-approval`
- **Update** the `Prepare Slack Notification` node in Workflow 1:
  - Replace `YOUR_N8N_BASE_URL` with your actual n8n URL

**In Workflow 3** (n8n-workflow-3-script-writing.json):
- Workflow 2 triggers this via `YOUR_N8N_BASE_URL/webhook/ugc-phase3`
- **Update** the `Trigger Workflow 3` node in Workflow 2:
  - Replace `YOUR_N8N_BASE_URL` with your actual n8n URL

**In Workflow 4** (n8n-workflow-4-delivery.json):
- Workflow 3 triggers this via Slack buttons with `YOUR_N8N_BASE_URL/webhook/ugc-delivery`
- **Update** the `Prepare PM Notification` node in Workflow 3

### Quick Find & Replace

In each JSON file, do a global find-and-replace:
- Replace `YOUR_N8N_BASE_URL` → your actual n8n URL (e.g., `https://smashed.app.n8n.cloud`)
- Replace `YOUR_AIRTABLE_BASE_ID` → your Airtable base ID (e.g., `appXXXXXXXXXX`)
- Replace `YOUR_AIRTABLE_CREDENTIAL_ID` → the n8n credential ID for Airtable
- Replace `YOUR_OPENAI_CREDENTIAL_ID` → the n8n credential ID for OpenAI
- Replace `YOUR_SERPAPI_CREDENTIAL_ID` → the n8n credential ID for SerpAPI
- Replace `YOUR_GOOGLE_SHEETS_CREDENTIAL_ID` → the n8n credential ID for Google Sheets
- Replace `YOUR_GOOGLE_DRIVE_CREDENTIAL_ID` → the n8n credential ID for Google Drive
- Replace `YOUR_SLACK_CREDENTIAL_ID` → the n8n credential ID for Slack
- Replace `YOUR_CLICKUP_API_CREDENTIAL_ID` → the n8n credential ID for ClickUp

> **Tip**: After importing into n8n, you can also update credentials by clicking each node and selecting the right credential from the dropdown. This is often easier than editing the JSON.

---

## 6. Google Sheets Template

Create a Google Sheet with these two tabs:

### Tab: "Client Database"

Columns (Row 1 headers):

```
client_code | brand_name | client_name | client_email | website_url | product_feature | differentiator | competitors | competitor_strengths | target_user | biggest_problem | main_hesitation | social_proof | selling_proposition | brand_personality | credibility_point | transformation | best_concepts | compliance | reference_ads | available_assets | do_not_say | additional_notes | num_scripts
```

### Tab: "Script Agent Log"

Columns (Row 1 headers):

```
Timestamp | Client Code | Brand | Status | Scripts | QA Score | Revisions | Summary
```

**Copy the Google Sheet ID** (from the URL: `docs.google.com/spreadsheets/d/{THIS_PART}/edit`) and replace `1cB4wtyp0l0xwH2Ukw-U93eW9_Ix1lB6EroYs1GyDLCM` in the workflow files.

---

## 7. Tally Onboarding Form

Create a Tally form with fields matching the Client Database columns. See the onboarding workflow file for the exact field mapping.

Connect Tally to Workflow 0 (onboarding) via webhook:
- In Tally: Form Settings → Integrations → Webhook
- URL: `YOUR_N8N_BASE_URL/webhook/ugc-onboarding`

---

## 8. Slack Configuration

### Channel Setup

Create or use an existing Slack channel for script agent notifications. Update the channel ID in the workflow files:
- Find: `C07MN9QA1R7`
- Replace with: your channel ID (right-click channel → View channel details → scroll to bottom)

### PM User ID

For error DMs, update the user ID:
- Find: `U06P9F49BJT`
- Replace with: your PM's Slack user ID

---

## 9. Testing & Validation

### Step 1: Test Onboarding

```bash
curl -X POST YOUR_N8N_BASE_URL/webhook/ugc-onboarding \
  -H "Content-Type: application/json" \
  -d '{
    "brand_name": "TestBrand",
    "client_name": "Test Client",
    "client_email": "test@example.com",
    "website_url": "https://example.com",
    "product_feature": "Vitamin C Serum with 20% concentration",
    "differentiator": "Uses stabilized vitamin C that does not oxidize",
    "competitors": "The Ordinary, Drunk Elephant, SkinCeuticals",
    "target_user": "Women 25-40 with hyperpigmentation",
    "biggest_problem": "Dark spots and uneven skin tone",
    "main_hesitation": "Previous serums oxidized and turned orange",
    "num_scripts": "4"
  }'
```

**Expected**: Client added to Google Sheets, Slack notification, Airtable record created.

### Step 2: Test Research + Concepts (Workflow 1)

```bash
curl -X POST YOUR_N8N_BASE_URL/webhook/ugc-phase1 \
  -H "Content-Type: application/json" \
  -d '{ "client_code": "TES-0214" }'
```

**Expected**: Research stored in Airtable, 6 concepts stored (for 4 scripts ordered), Slack message to PM with approval buttons.

### Step 3: Test PM Approval (Workflow 2)

```bash
# Approve all concepts
curl -X POST YOUR_N8N_BASE_URL/webhook/ugc-concept-approval \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "PASTE_PROJECT_ID_FROM_AIRTABLE",
    "action": "pm_approve",
    "concept_ids": [],
    "notes": "All concepts look great"
  }'
```

**Expected**: Concepts updated in Airtable (pm_status: Approved), Slack to client.

### Step 4: Test Client Approval (Workflow 2)

```bash
curl -X POST YOUR_N8N_BASE_URL/webhook/ugc-concept-approval \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "PASTE_PROJECT_ID",
    "action": "client_approve",
    "concept_ids": ["CONCEPT_ID_1", "CONCEPT_ID_2", "CONCEPT_ID_3", "CONCEPT_ID_4"],
    "notes": "Love concepts 1, 2, 4, 6"
  }'
```

**Expected**: Approved concepts updated, Workflow 3 auto-triggered, scripts written for approved concepts only.

### Step 5: Test Delivery (Workflow 4)

```bash
curl -X POST YOUR_N8N_BASE_URL/webhook/ugc-delivery \
  -H "Content-Type: application/json" \
  -d '{
    "project_id": "PASTE_PROJECT_ID",
    "action": "approve",
    "script_ids": [],
    "notes": ""
  }'
```

**Expected**: Scripts formatted, Google Docs populated, ClickUp updated, Slack notification, project status → Delivered.

---

## 10. Cost Breakdown

### Per Client Run (Estimated)

| Service | Usage | Cost |
|---------|-------|------|
| OpenAI (Research — GPT-4o-mini) | ~3,000 input + ~3,000 output tokens | ~$0.005 |
| OpenAI (Strategy — GPT-4o) | ~8,000 input + ~5,000 output tokens | ~$0.15 |
| OpenAI (Writer — GPT-4o) | ~10,000 input + ~8,000 output tokens | ~$0.30 |
| OpenAI (QA — GPT-4o-mini) | ~8,000 input + ~3,000 output tokens | ~$0.005 |
| SerpAPI | ~10-15 searches | Free tier or ~$0.10 |
| **Total per client** | | **~$0.50-0.60** |

### Monthly Estimates

| Clients/Month | OpenAI | SerpAPI | Airtable | n8n | Total |
|---------------|--------|---------|----------|-----|-------|
| 5 | ~$3 | Free (100) | Free | Free/self-host | ~$3 |
| 15 | ~$9 | $50 | Free | Free/self-host | ~$59 |
| 30 | ~$18 | $50 | $20 | Free/self-host | ~$88 |
| 50+ | ~$30 | $50 | $20 | $20 (cloud) | ~$120 |

### Token Savings from Approval Gates

Without approval gates: Write scripts for ALL concepts (1.5x)
With approval gates: Write scripts for APPROVED concepts only (1x)

**Savings**: ~33% reduction in the most expensive phase (GPT-4o script writing).
At 30 clients/month, that's ~$6/month saved — pays for the Airtable upgrade.

---

## 11. Troubleshooting

### Common Issues

**"No client found" error in Workflow 1**
- Check that the `client_code` in the webhook payload matches a row in your Google Sheet "Client Database" tab
- Ensure the Google Sheet ID in the workflow matches your actual sheet

**SerpAPI returning empty results**
- Check your API key is valid: https://serpapi.com/manage-api-key
- Check you haven't exceeded the free tier (100 searches/month)
- Some queries may return no results — the agent handles this gracefully

**Airtable "INVALID_PERMISSIONS" error**
- Your Personal Access Token needs scopes: `data.records:read`, `data.records:write`, `schema.bases:read`
- Make sure the token has access to the correct base

**Slack buttons not working**
- Ensure `YOUR_N8N_BASE_URL` has been replaced with your actual n8n URL
- The n8n instance must be publicly accessible (not just localhost) for Slack buttons to work
- If self-hosting, use a reverse proxy (nginx/Caddy) with HTTPS

**Workflow 3 not triggering after client approval**
- Check the `Trigger Workflow 3` HTTP node in Workflow 2 has the correct URL
- Ensure Workflow 3 is activated (not just saved) in n8n

**QA revision loop stuck**
- The system allows max 2 revision cycles, then auto-approves
- If scripts are consistently failing QA, check compliance rules in the brief

### Support

For n8n issues: https://community.n8n.io
For workflow bugs: Check execution logs in n8n (Executions tab)

---

## File Reference

| File | Purpose | Webhook |
|------|---------|---------|
| `n8n-ugc-onboarding-workflow.json` | Client onboarding form → Sheets → Slack → Airtable | `/webhook/ugc-onboarding` |
| `n8n-workflow-1-research-concepts.json` | Research + Concepts → Airtable → PM notification | `/webhook/ugc-phase1` |
| `n8n-workflow-2-concept-approval.json` | PM/Client approval gates | `/webhook/ugc-concept-approval` |
| `n8n-workflow-3-script-writing.json` | Write scripts for approved concepts → QA → Airtable | `/webhook/ugc-phase3` |
| `n8n-workflow-4-delivery.json` | Final delivery → Google Docs + ClickUp + Slack | `/webhook/ugc-delivery` |
| `n8n-ugc-script-writing-agent.json` | Original monolithic workflow (backup/reference) | `/webhook/ugc-script-agent` |
