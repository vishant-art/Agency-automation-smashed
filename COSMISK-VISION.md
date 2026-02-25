# COSMISK — The Complete Vision

> Built by Vishat Jain. Not another agency tool. An AI-native creative infrastructure company.

---

## WHAT EXISTS TODAY (Foundation)

- 21 active n8n workflows, 7 named agents, 400+ nodes
- Full UGC production pipeline: Onboarding → Research → Approval → Scripts → Delivery
- AI script writing (Gemini 2.5 Flash) with industry personas, QA scoring, reference ad matching
- Multi-agent orchestration with event bus (Agent_Events table, Orchestrator v2 polls every 5 min)
- Automated lead generation: Prospect Finder (SerpAPI + Gemini), Ad Library Scanner (Meta Ad Library)
- Outreach automation: Gemini-drafted personalized messages, multi-platform, 3-day follow-up cadence
- Client comms, media monitoring, weekly reporting, comment-based script revision
- Sales pipeline with proposal generation
- Creator scout and matching
- Angular dashboard (Cosmisk frontend)
- Smashed Agency running live on this system

This is the foundation. Here's where it goes.

---

## PHASE 1: KILLER AGENCY (Now → 8 weeks)

Goal: Make Smashed the most efficient creative agency in India. Zero wasted time. Every decision data-driven. Every follow-up automatic.

### 1.1 — AI Video Generation Pipeline

**What:** Add a parallel "AI-only" production lane alongside human creator content. Same scripts from Phase 3, but rendered as synthetic UGC using AI video tools.

**How it works:**
```
Approved Script
  ├── Human Track: Creator matched → filmed → edited → delivered (existing Phase 4)
  └── AI Track (NEW):
       Script → ElevenLabs voice generation → HeyGen avatar render → B-roll via Kling 3.0
       → Auto-composite → Upload to client review folder
```

**Tech stack:**
- Kling 3.0 via fal.ai API: $0.075/second, 15-second clips, native audio, 5 languages
- HeyGen API: $0.50-0.99/credit (1 min video), UGC-style avatars, Avatar IV photorealistic
- ElevenLabs API: $22/mo for voice cloning, sub-500ms latency
- Google Veo 3.1 for premium cinematic B-roll: $0.40-0.75/second

**Cost per AI-generated UGC video:** $2-8 depending on length and quality tier
**Cost of a real creator shoot:** $200-500+

**The play:** Client gets 5 real creator videos + 20 AI variations for A/B testing. The AI videos test hooks, CTAs, and formats at 1/50th the cost. Winning concepts get produced with real creators. Losing concepts die before you waste a creator's time.

**n8n implementation:** New Phase 3.5 workflow:
1. Webhook trigger: receives approved script + brand assets
2. Code node: formats script into ElevenLabs SSML + HeyGen scene JSON
3. HTTP Request: ElevenLabs TTS API → generates voiceover audio
4. HTTP Request: HeyGen Video Generation API → renders avatar with voiceover
5. HTTP Request: Kling 3.0 API → generates B-roll clips from scene descriptions
6. Code node: builds video edit timeline (FFmpeg or Creatomate API)
7. HTTP Request: uploads to Google Drive delivery folder
8. Slack notification + event write

**Timeline:** 2 weeks to build, 1 week to test

---

### 1.2 — Creative Testing Flywheel

**What:** Automatically generate ad creative variations, launch them to Meta as dark posts, measure performance, and feed results back into the script writing system.

**The loop:**
```
Phase 3 Script → AI Video Pipeline → 20 variations generated
  → Score with AdCreative.ai prediction engine (pre-launch)
  → Launch top 5 to Meta via Graph API as dark posts
  → Media Monitor tracks performance (existing Agent 6)
  → Performance data feeds back into Phase 1 Research prompts
  → Next script batch uses winning patterns
  → Repeat every 48 hours
```

**Why this matters:** Creative accounts for 55-70% of campaign performance (2026 industry data). The agency that tests fastest wins. Traditional agencies test 3-5 creatives per week. With this system: 20-50 per week, automated.

**Tech stack:**
- AdCreative.ai API (~$200/mo): Pre-launch creative scoring
- Meta Marketing API (existing credential `G4AHd7ZseuLWhZkk`): Programmatic ad creation
- Motion ($250/mo, unlimited seats): Post-launch creative analytics, element-level performance breakdown

**What Motion gives you that nobody else has:** It auto-tags every creative with AI — hook type, visual style, CTA text, talent demographic, setting — and correlates each element with ROAS. You stop saying "this ad worked" and start saying "problem-solution hooks with female talent aged 25-35 in outdoor settings outperform by 340% for skincare brands."

**That insight writes the next Gemini prompt automatically.**

**n8n implementation:** New Phase 5 workflow (Creative Testing):
1. Schedule trigger: runs daily
2. Fetch delivered scripts with AI video variants
3. HTTP Request: AdCreative.ai scoring API
4. Code node: rank and select top performers
5. HTTP Request: Meta Marketing API — create campaign + ad set + ad creatives
6. HTTP Request: write to Agent_Events (test_launched)
7. Media Monitor picks up performance data → Orchestrator routes to Phase 1 as context

**Timeline:** 3 weeks

---

### 1.3 — Intent-Driven Lead Machine

**What:** Stop cold outreach. Start warm outreach based on real buying signals.

**Intent signals to monitor:**

| Signal | Source | Meaning | Priority |
|--------|--------|---------|----------|
| Hired "UGC creator" or "content marketing manager" | LinkedIn Jobs API / Google | They're investing in content | HIGH |
| Meta ad spend increased 50%+ MoM | Media Monitor (existing) | Scaling = need more creatives | HIGH |
| Raised Series A/B | Crunchbase API / Google News | Marketing budget unlocked | HIGH |
| Featured on Shark Tank India | Google News / YouTube | Instant brand awareness, need content NOW | CRITICAL |
| Launched on new platform (IG → YouTube) | Social monitoring | Need new content formats | MEDIUM |
| Running Meta ads without UGC | Ad Library Scanner (existing) | Low-hanging fruit for us | MEDIUM |
| Competitor started running UGC ads | Ad Library Scanner | They'll want to match | MEDIUM |

**The killer outreach:** When we detect a brand running poor-performing ads (low CTR, stale creative), we auto-generate:
1. A personalized creative tear-down of their current ads (what's not working, why)
2. A sample AI-generated UGC script specifically for their product
3. An AI-rendered 15-second video sample using HeyGen + their product images

The outreach message: "We analyzed your Meta ads and found 3 opportunities. Here's a sample script we wrote for [your product]. And here's what it looks like as a video. Imagine 10 of these, every month."

**Nobody sends a custom video sample in cold outreach. This is the nuclear option.**

Cost per prospect: ~$5-10 (Gemini analysis + ElevenLabs + HeyGen)
Conversion rate for personalized video outreach: 3-5x vs text-only

**Multi-touch sequence (replace single-message outreach):**
1. Day 0: Instagram DM with the video sample link
2. Day 2: LinkedIn connection request + note referencing their recent activity
3. Day 5: Email with full creative tear-down + case study from their industry
4. Day 8: WhatsApp voice note (AI-generated via ElevenLabs, sounds human)
5. Day 12: Follow-up with competitor insight

**Tech stack additions:**
- Clay ($149-500/mo): Data enrichment, 50+ sources, intent signals
- Instantly ($37-358/mo): Cold email infrastructure, deliverability, warmup
- Both have APIs that feed directly into `/add-lead` webhook

**n8n implementation:** Upgrade Prospect Finder + new Agent 8 (Intent Monitor):
1. Schedule: runs 3x daily
2. Monitors: Google News API, LinkedIn Jobs (via SerpAPI), Crunchbase, Product Hunt
3. Scores each signal 0-100 based on relevance + recency + company size
4. High-score signals: auto-generate video sample → trigger outreach sequence
5. Medium signals: add to nurture pipeline
6. Low signals: log and decay over time

**Timeline:** 3 weeks

---

### 1.4 — Client Intelligence Dashboard (Cosmisk v2)

**What:** Rebuild the Angular dashboard from "basic data display" to "the only tool the client needs."

**Client view:**
```
┌──────────────────────────────────────────────────────────────┐
│  WHEELWASH — Campaign Dashboard                               │
├──────────────┬──────────────┬──────────────┬─────────────────┤
│ Active       │ Scripts in   │ Avg ROAS     │ Creative        │
│ Scripts: 12  │ Review: 3    │ 2.8x         │ Health: 🟢      │
├──────────────┴──────────────┴──────────────┴─────────────────┤
│                                                               │
│  📊 Performance Trends (last 30 days)                         │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                          │
│                                                               │
│  🎯 AI Recommendations:                                      │
│  • Hooks under 3 sec perform 2.3x better — shorter hooks     │
│    recommended for next batch                                 │
│  • "Before/After" format outperforming "Testimonial" by 40%  │
│  • Competitor XYZ launched 5 new UGC ads this week — suggest  │
│    response campaign                                          │
│                                                               │
│  📋 Active Projects                                           │
│  ┌─────────────────────────────────────────────────────┐     │
│  │ Feb Batch  ●●●●●○○○○○  Research → [Approval] → ... │     │
│  │ Jan Batch  ●●●●●●●●●●  Delivered ✓ (ROAS: 3.1x)   │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
│  [Approve Concepts]  [Request Revision]  [Order New Batch]   │
└──────────────────────────────────────────────────────────────┘
```

**One-click actions from dashboard:**
- Approve/reject concepts (triggers Phase 2 webhook)
- Request script revisions with comments (triggers Script Revision webhook)
- Order new batch (triggers Onboarding with existing brand data)
- Download all delivered scripts
- View competitor ad analysis

**PM internal view:**
- All clients in one view with status, health, and alerts
- Revenue tracking per brand
- Creator utilization and matching
- System health (workflow errors, API usage)

**Timeline:** 4 weeks (parallel with other work)

---

### 1.5 — Performance Feedback Loop (Closed-Loop Creative Intelligence)

**What:** Every script that becomes an ad generates performance data. That data improves future scripts.

**The data that flows back:**

```
Script Record (Airtable)
├── qa_score: 8.5/10 (internal quality)
├── hook_type: "problem-solution"
├── format: "testimonial"
├── talent_demo: "female, 25-35"
├── duration: "30s"
├── cta_type: "free-trial"
│
├── PERFORMANCE (from Meta API after 7 days):
│   ├── impressions: 45,000
│   ├── ctr: 2.1%
│   ├── cpc: $0.85
│   ├── roas: 3.2x
│   ├── hook_rate: 68% (3-second view rate)
│   └── completion_rate: 34%
│
└── INSIGHT (generated by Gemini after performance data):
    └── "Problem-solution hooks with specific pain points outperform
         generic hooks by 2.1x for skincare. Female talent 25-35
         drives 40% higher completion rate. 30s format optimal for
         this brand — 15s shows lower ROAS due to rushed CTA."
```

**Where this data goes:**
1. Script_Library — tagged with performance tier (Top/Good/Average/Low)
2. Phase 1 Research — Gemini prompt includes: "Based on performance data, prioritize [X] hook types and [Y] formats for this brand"
3. Phase 3 Script Writing — Gemini prompt includes: "This brand's top-performing scripts use [specific patterns]. Weight your output toward these patterns."
4. Weekly Report — "Your best-performing creative this week was [X]. Here's why it worked: [AI analysis]."

**This is the data flywheel.** After 6 months of running campaigns, you have the largest dataset of "what UGC scripts actually perform" in India. That dataset is the moat. Every new client benefits from every previous client's performance data (anonymized).

---

## PHASE 2: SELL THE SYSTEM (8-20 weeks)

Goal: Package everything as Cosmisk SaaS. First 5 agency customers.

### 2.1 — Multi-Tenant Architecture

**Migration path:** Airtable → Supabase

```
Current (single-tenant):
  Airtable Base → All data in one place
  n8n Workflows → Hardcoded base/table IDs

Future (multi-tenant):
  Supabase PostgreSQL
  ├── Row-Level Security: org_id on every table
  ├── Realtime: WebSocket subscriptions for live dashboards
  ├── Auth: Built-in email/OAuth, JWT claims include org_id
  ├── Storage: File uploads (scripts, assets, invoices)
  └── Edge Functions: Server-side logic

  n8n Workflows
  ├── Tenant ID passed in every webhook call
  ├── All Airtable HTTP Requests → Supabase REST API
  └── Event bus → Supabase Realtime channels per tenant
```

**Database schema (Supabase):**

```sql
-- Every table has org_id for RLS
CREATE TABLE organizations (
  id UUID PRIMARY KEY,
  name TEXT,
  plan TEXT, -- 'starter', 'growth', 'enterprise'
  created_at TIMESTAMPTZ
);

CREATE TABLE brands (
  id UUID PRIMARY KEY,
  org_id UUID REFERENCES organizations(id),
  brand_name TEXT,
  -- ... all current Airtable fields
);

-- RLS Policy: users only see their org's data
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own org" ON brands
  USING (org_id = auth.jwt() ->> 'org_id');
```

**What this enables:**
- Agency A's data is physically impossible to see from Agency B's login
- Each agency gets their own dashboard URL: `app.cosmisk.ai/agency-name`
- White-labeling: agency's logo, colors, domain
- Usage tracking per tenant for billing

**Effort:** 3-4 weeks for core migration + 2 weeks for testing

### 2.2 — Pricing Model

**Three tiers that capture all revenue modes:**

| Tier | Price | What They Get |
|------|-------|---------------|
| **Starter** | $497/mo | Dashboard, script generation (50/mo), basic reporting, email support |
| **Growth** | $2,497/mo | Everything in Starter + AI video generation (20/mo), creative testing, lead gen tools, Slack integration, priority support |
| **Enterprise** | $4,997/mo + performance % | Everything in Growth + unlimited scripts, dedicated account manager, custom agent workflows, white-label client portal, Meta API integration, SLA |

**Usage-based add-ons:**
- Additional AI videos: $5 each
- Additional scripts beyond plan: $10 each
- Custom agent workflow: $2,000 one-time setup
- Supabase data export: included

**Why this works:**
- Starter catches small agencies trying AI for the first time ($6K/yr)
- Growth is the sweet spot — enough value to justify the price, enough margin for us
- Enterprise locks in large agencies with performance alignment

**Revenue projection (Year 1):**
- 20 Starter agencies × $497 = $9,940/mo
- 10 Growth agencies × $2,497 = $24,970/mo
- 3 Enterprise × $4,997 = $14,991/mo
- **Total: ~$50K/mo recurring** + setup fees + performance bonuses

### 2.3 — MCP Integration (The Invisible Interface)

**What MCP Apps enables (announced Jan 2026):**

Tools can now return interactive UI components that render inside AI conversations. Your PM opens Claude Desktop and says:

> "Show me all projects that need attention"

Claude calls your MCP server (an n8n workflow with MCP Server Trigger). The workflow fetches Projects from Supabase, identifies overdue items, and returns an interactive card:

```
┌─────────────────────────────────────────┐
│ 🔴 Wheelwash Feb Batch                  │
│ Status: Script Review (48h overdue)     │
│ [Approve All] [View Scripts] [Escalate] │
├─────────────────────────────────────────┤
│ 🟡 GlowVita March Batch                │
│ Status: Research (on track)             │
│ [View Concepts] [Skip to Scripts]       │
└─────────────────────────────────────────┘
```

The PM clicks [Approve All] — the button triggers the Phase 2 webhook. No dashboard needed. No login needed. The AI conversation IS the interface.

**MCP tools to expose:**
1. `get_project_status` — returns interactive project cards
2. `approve_concepts` — approve/reject with one click
3. `generate_scripts` — trigger script generation for a brand
4. `get_lead_pipeline` — show sales pipeline with actions
5. `run_ad_analysis` — trigger ad analysis and return results inline
6. `get_weekly_report` — generate and display report in-conversation

**This is the future of agency software.** Not dashboards. Not logins. Conversational interfaces with action buttons.

---

## PHASE 3: AI AGENCY INFRASTRUCTURE (20-52 weeks)

Goal: Become the Shopify of creative agencies.

### 3.1 — Agent Marketplace

Other agencies can't build n8n workflows. But they can install pre-built agents.

**The Cosmisk Agent Store:**

```
┌──────────────────────────────────────────────┐
│  🏪 Cosmisk Agent Store                       │
│                                               │
│  📦 Lead Generation Pack         $199/mo      │
│     Prospect Finder + Ad Library Scanner      │
│     + Outreach Automation + Calendar Connect  │
│     [Install]                                 │
│                                               │
│  📦 Creative Intelligence Pack   $299/mo      │
│     AI Script Writer + Creative Testing       │
│     + Performance Feedback Loop               │
│     [Install]                                 │
│                                               │
│  📦 Client Ops Pack             $149/mo       │
│     Daily Ops + Client Comms + Reporting      │
│     + Media Monitor                           │
│     [Install]                                 │
│                                               │
│  📦 Full Autopilot              $497/mo       │
│     All agents + Orchestrator + Event Bus     │
│     [Install]                                 │
└──────────────────────────────────────────────┘
```

Each "install" provisions:
1. Creates the n8n workflows in the agency's workspace (or shared Cosmisk infra)
2. Connects to their Supabase tenant
3. Configures their Slack/Discord
4. Sets up their Meta/Google credentials
5. Runs an onboarding wizard

### 3.2 — Cross-Agency Intelligence Network

When Agency B joins Cosmisk, their performance data (anonymized) improves the system for Agency A.

**What this looks like:**
- Script_Library grows from 56 (Smashed only) to 5,000+ (all agencies combined)
- Performance data covers every industry, every format, every hook type
- Gemini prompts include: "Across 50 agencies, the top-performing hook pattern for [skincare] is [X]. The optimal video length is [Y]. The best-converting CTA is [Z]."

**This is the network effect.** More agencies = better scripts for everyone = more agencies join.

### 3.3 — White-Label Client Portal

Agencies resell Cosmisk as their own product.

```
Client sees:     [Agency Brand] Creative Platform
                  Powered by [Agency Name]

Agency sees:     Cosmisk Dashboard
                  Managing 15 brands across 3 clients

Cosmisk sees:    Infrastructure Dashboard
                  42 agencies, 380 brands, $2.1M MRR
```

---

## THE 10 AGENTS (Final Architecture)

| # | Agent | Role | Status |
|---|-------|------|--------|
| 1 | **Daily Ops** | Morning briefing, overnight events summary, team priorities | LIVE |
| 2 | **Orchestrator** | Event-driven decision engine, routes work between all agents | LIVE |
| 3 | **Creator Scout** | Finds and matches creators to scripts based on requirements | LIVE |
| 4 | **Client Comms** | Automated status updates, proactive communication | LIVE |
| 5 | **Sales Pipeline** | Lead management, proposal generation, follow-up automation | LIVE |
| 6 | **Media Monitor** | Meta ad performance tracking, fatigue detection, competitor watch | LIVE |
| 7 | **Reporting** | Weekly brand reports, lead gen digests, performance summaries | LIVE |
| 8 | **Trend Intelligence** | Google Trends, YouTube, Reddit, Product Hunt monitoring → feeds insights into script system | BUILD NEXT |
| 9 | **Quality Auditor** | Continuous system health monitoring, script quality trends, client satisfaction signals, auto-improvement recommendations | BUILD NEXT |
| 10 | **Growth Engine** | Analyzes conversion data, A/B tests outreach messages, adjusts Prospect Finder queries based on what actually converts, optimizes pricing | BUILD NEXT |

---

## THE MOAT (Why Nobody Can Copy This)

### 1. Data Flywheel
Every script written → every ad launched → every ROAS data point → improves the next script. After 6 months with 10 brands: largest UGC performance dataset in India. After 1 year with 50 agencies on the platform: the dataset becomes the product.

### 2. Multi-Agent Orchestration
10 AI agents coordinating through an event bus with autonomous decision-making. This is months of engineering. By the time a competitor starts building, we're two versions ahead. The event bus architecture is the secret — it makes the system composable. New agents plug in without touching existing ones.

### 3. Industry-Specific Intelligence
Script_Library: 56 reference scripts across 9 industries today. After 50 clients: 500+ scripts with performance data. After 50 agencies: 5,000+ scripts. This library IS the competitive advantage. It's what makes our Gemini prompts better than anyone else's.

### 4. Network Effects (Phase 3)
When Agency B joins Cosmisk, their anonymized performance data improves scripts for Agency A. More agencies = better system = more agencies. This is the classic SaaS flywheel that makes the platform more valuable the bigger it gets.

### 5. Switching Cost
Once an agency has their brands, creators, scripts, performance history, and client portals on Cosmisk, moving is painful. Their clients are logged into OUR dashboard. Their workflows reference OUR event bus. The data gravity keeps them.

---

## REVENUE ROADMAP

| Timeline | Revenue Source | Monthly |
|----------|---------------|---------|
| Now | Smashed Agency (2 brands) | $6K |
| Month 2 | Smashed (5 brands) + AI video upsells | $25K |
| Month 4 | Smashed (8 brands) + first 3 SaaS agencies | $50K |
| Month 6 | Smashed (8 brands) + 10 SaaS agencies + consulting | $80K |
| Month 9 | 8 direct + 20 SaaS + performance fees | $120K |
| Month 12 | 8 direct + 30 SaaS + marketplace + performance | $200K |

---

## TOTAL INFRASTRUCTURE COST

| Tool | Monthly Cost | Purpose |
|------|-------------|---------|
| n8n Cloud (or self-hosted) | $50-200 | Workflow engine |
| Supabase Pro | $25 | Database + Auth + Realtime |
| Gemini 2.5 Flash | ~$50-100 | All AI text generation |
| HeyGen API | $330 | AI video avatars |
| ElevenLabs Pro | $99 | Voice cloning + TTS |
| Kling 3.0 (fal.ai) | ~$200 | AI video generation |
| Motion | $250 | Creative analytics |
| Clay + Instantly | ~$500 | Lead enrichment + cold email |
| AdCreative.ai | ~$200 | Pre-launch creative scoring |
| SerpAPI | $50 | Search data |
| **Total** | **~$1,750/mo** | |

$1,750/month to run an operation that replaces a 15-person team.

---

## WHAT TO BUILD FIRST (Priority Order)

1. **Agent 8: Trend Intelligence** — highest leverage for immediate lead quality improvement
2. **AI Video Pipeline (Phase 3.5)** — the "nuclear option" for client acquisition (send prospects a custom video sample)
3. **Creative Testing Flywheel** — the feature that makes retention sticky (clients see continuous improvement)
4. **MCP Server** — expose the entire system as AI-callable tools
5. **Supabase migration** — when first external agency signs up
6. **Agent Store** — when 5+ agencies are on the platform

---

*This document is the living blueprint. Every feature described above is technically feasible with the current stack (n8n + Gemini + existing APIs). The question isn't "can we build this" — it's "how fast can we ship."*

*— Built with Claude Code, Feb 2026*
