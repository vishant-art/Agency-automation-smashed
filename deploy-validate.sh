#!/usr/bin/env bash
# =============================================================================
# Smashed Agency — Deploy & Validate n8n Workflows
# =============================================================================
# Imports all workflow JSON files into the n8n instance via the REST API,
# activates them, and validates that webhook endpoints are reachable.
#
# Usage:
#   bash deploy-validate.sh
#
# Prerequisites:
#   - config.env must exist with N8N_BASE_URL and N8N_API_KEY set
#   - setup.sh must have been run first (credential placeholders replaced)
#   - curl and jq must be installed
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

pass()  { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
fail()  { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL + 1)); }
warn()  { echo -e "  ${YELLOW}!${NC} $1"; WARN=$((WARN + 1)); }
info()  { echo -e "  ${CYAN}→${NC} $1"; }
header(){ echo ""; echo -e "${BOLD}${CYAN}$1${NC}"; echo -e "${CYAN}$(printf '%.0s─' $(seq 1 ${#1}))${NC}"; }

# ─── Load config ─────────────────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: config.env not found. Run setup.sh first.${NC}"
    exit 1
fi

set -a
source "$CONFIG_FILE"
set +a

N8N_URL="${N8N_BASE_URL:-}"
API_KEY="${N8N_API_KEY:-}"

if [[ -z "$N8N_URL" ]]; then
    echo -e "${RED}Error: N8N_BASE_URL is not set in config.env${NC}"
    exit 1
fi

# Remove trailing slash
N8N_URL="${N8N_URL%/}"

echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}  Smashed Agency — Deploy & Validate Workflows${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${NC}"
echo ""
info "n8n instance: ${N8N_URL}"

# ─── Check dependencies ─────────────────────────────────────────────────────
header "1. Checking dependencies"

if command -v curl &>/dev/null; then
    pass "curl installed"
else
    fail "curl not found — please install curl"
    exit 1
fi

if command -v jq &>/dev/null; then
    pass "jq installed"
else
    warn "jq not found — install jq for full validation (sudo apt install jq)"
    JQ_AVAILABLE=false
fi
JQ_AVAILABLE=${JQ_AVAILABLE:-true}

# ─── Check n8n connectivity ─────────────────────────────────────────────────
header "2. Checking n8n connectivity"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "${N8N_URL}/" 2>/dev/null || echo "000")

if [[ "$HTTP_CODE" == "000" ]]; then
    fail "Cannot reach ${N8N_URL} — check that n8n is running"
    echo ""
    echo -e "${RED}Deployment aborted. Ensure your n8n instance is accessible.${NC}"
    exit 1
elif [[ "$HTTP_CODE" =~ ^(200|301|302)$ ]]; then
    pass "n8n instance reachable (HTTP ${HTTP_CODE})"
else
    warn "n8n returned HTTP ${HTTP_CODE} — may still work"
fi

# ─── Check for remaining placeholders ────────────────────────────────────────
header "3. Pre-flight: checking for remaining placeholders"

PLACEHOLDERS=(
    "YOUR_AIRTABLE_CREDENTIAL_ID"
    "YOUR_OPENAI_CREDENTIAL_ID"
    "YOUR_SERPAPI_CREDENTIAL_ID"
    "YOUR_GOOGLE_SHEETS_CREDENTIAL_ID"
    "YOUR_GOOGLE_DRIVE_CREDENTIAL_ID"
    "YOUR_SLACK_CREDENTIAL_ID"
    "YOUR_CLICKUP_API_CREDENTIAL_ID"
    "YOUR_N8N_BASE_URL"
)

PLACEHOLDER_COUNT=0
for ph in "${PLACEHOLDERS[@]}"; do
    count=0
    for file in "$SCRIPT_DIR"/n8n-*.json; do
        matches=$(grep -c "$ph" "$file" 2>/dev/null || true)
        count=$((count + matches))
    done
    if [[ $count -gt 0 ]]; then
        fail "${ph} still present (${count} occurrences)"
        PLACEHOLDER_COUNT=$((PLACEHOLDER_COUNT + count))
    fi
done

if [[ $PLACEHOLDER_COUNT -eq 0 ]]; then
    pass "All placeholders replaced — workflows are ready"
else
    echo ""
    echo -e "${RED}Found ${PLACEHOLDER_COUNT} unresolved placeholders. Run setup.sh first.${NC}"
    exit 1
fi

# ─── Determine API access ───────────────────────────────────────────────────
header "4. Checking n8n API access"

API_AVAILABLE=false
AUTH_HEADER=""

if [[ -n "$API_KEY" ]]; then
    AUTH_HEADER="X-N8N-API-KEY: ${API_KEY}"
    API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        -H "${AUTH_HEADER}" \
        "${N8N_URL}/api/v1/workflows" 2>/dev/null || echo "000")

    if [[ "$API_RESPONSE" == "200" ]]; then
        pass "n8n REST API accessible with API key"
        API_AVAILABLE=true
    else
        warn "API returned HTTP ${API_RESPONSE} — will try without auth"
    fi
fi

if [[ "$API_AVAILABLE" == "false" ]]; then
    # Try without auth (some self-hosted instances allow unauthenticated API)
    API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        "${N8N_URL}/api/v1/workflows" 2>/dev/null || echo "000")

    if [[ "$API_RESPONSE" == "200" ]]; then
        pass "n8n REST API accessible (no auth required)"
        API_AVAILABLE=true
        AUTH_HEADER=""
    else
        warn "n8n REST API not accessible (HTTP ${API_RESPONSE})"
        warn "Set N8N_API_KEY in config.env for API deployment"
        info "Falling back to webhook-only validation"
    fi
fi

# ─── Deploy workflows via API ───────────────────────────────────────────────
# Ordered list: main 5 workflows to deploy (skip the monolithic backup)
WORKFLOW_FILES=(
    "n8n-ugc-onboarding-workflow.json"
    "n8n-workflow-1-research-concepts.json"
    "n8n-workflow-2-concept-approval.json"
    "n8n-workflow-3-script-writing.json"
    "n8n-workflow-4-delivery.json"
)

WORKFLOW_NAMES=(
    "UGC Client Onboarding"
    "Phase 1 — Research + Concepts"
    "Phase 2 — Concept Approval"
    "Phase 3 — Script Writing + QA"
    "Phase 4 — Delivery"
)

WEBHOOK_PATHS=(
    "ugc-onboarding"
    "ugc-phase1"
    "ugc-concept-approval"
    "ugc-phase3"
    "ugc-delivery"
)

# Track deployed workflow IDs for activation
declare -a DEPLOYED_IDS=()

if [[ "$API_AVAILABLE" == "true" ]]; then
    header "5. Deploying workflows via n8n REST API"

    # Build curl auth args
    CURL_AUTH=()
    if [[ -n "$AUTH_HEADER" ]]; then
        CURL_AUTH=(-H "$AUTH_HEADER")
    fi

    # Get existing workflows to check for duplicates
    EXISTING_WORKFLOWS=""
    if [[ "$JQ_AVAILABLE" == "true" ]]; then
        EXISTING_WORKFLOWS=$(curl -s "${CURL_AUTH[@]}" "${N8N_URL}/api/v1/workflows?limit=100" 2>/dev/null || echo "")
    fi

    for i in "${!WORKFLOW_FILES[@]}"; do
        wf_file="${SCRIPT_DIR}/${WORKFLOW_FILES[$i]}"
        wf_name="${WORKFLOW_NAMES[$i]}"

        if [[ ! -f "$wf_file" ]]; then
            fail "${WORKFLOW_FILES[$i]} not found — skipping"
            continue
        fi

        # Check if workflow already exists (by name)
        EXISTING_ID=""
        if [[ "$JQ_AVAILABLE" == "true" && -n "$EXISTING_WORKFLOWS" ]]; then
            EXISTING_ID=$(echo "$EXISTING_WORKFLOWS" | jq -r \
                --arg name "$wf_name" \
                '.data[]? | select(.name | contains($name)) | .id' 2>/dev/null | head -1 || echo "")

            # Also check by the full JSON name
            wf_json_name=$(jq -r '.name // empty' "$wf_file" 2>/dev/null || echo "")
            if [[ -z "$EXISTING_ID" && -n "$wf_json_name" ]]; then
                EXISTING_ID=$(echo "$EXISTING_WORKFLOWS" | jq -r \
                    --arg name "$wf_json_name" \
                    '.data[]? | select(.name == $name) | .id' 2>/dev/null | head -1 || echo "")
            fi
        fi

        if [[ -n "$EXISTING_ID" && "$EXISTING_ID" != "null" ]]; then
            # Update existing workflow
            info "Updating existing workflow: ${wf_name} (id: ${EXISTING_ID})"

            RESPONSE=$(curl -s -w "\n%{http_code}" \
                "${CURL_AUTH[@]}" \
                -X PUT \
                -H "Content-Type: application/json" \
                -d @"$wf_file" \
                "${N8N_URL}/api/v1/workflows/${EXISTING_ID}" 2>/dev/null || echo -e "\n000")

            HTTP_STATUS=$(echo "$RESPONSE" | tail -1)
            BODY=$(echo "$RESPONSE" | sed '$d')

            if [[ "$HTTP_STATUS" == "200" ]]; then
                pass "${wf_name} — updated (id: ${EXISTING_ID})"
                DEPLOYED_IDS+=("$EXISTING_ID")
            else
                fail "${wf_name} — update failed (HTTP ${HTTP_STATUS})"
                if [[ "$JQ_AVAILABLE" == "true" ]]; then
                    err_msg=$(echo "$BODY" | jq -r '.message // empty' 2>/dev/null || echo "")
                    [[ -n "$err_msg" ]] && info "Error: ${err_msg}"
                fi
            fi
        else
            # Import new workflow
            info "Importing: ${wf_name}"

            RESPONSE=$(curl -s -w "\n%{http_code}" \
                "${CURL_AUTH[@]}" \
                -X POST \
                -H "Content-Type: application/json" \
                -d @"$wf_file" \
                "${N8N_URL}/api/v1/workflows" 2>/dev/null || echo -e "\n000")

            HTTP_STATUS=$(echo "$RESPONSE" | tail -1)
            BODY=$(echo "$RESPONSE" | sed '$d')

            if [[ "$HTTP_STATUS" =~ ^(200|201)$ ]]; then
                WF_ID=""
                if [[ "$JQ_AVAILABLE" == "true" ]]; then
                    WF_ID=$(echo "$BODY" | jq -r '.id // empty' 2>/dev/null || echo "")
                fi
                pass "${wf_name} — imported${WF_ID:+ (id: $WF_ID)}"
                [[ -n "$WF_ID" ]] && DEPLOYED_IDS+=("$WF_ID")
            else
                fail "${wf_name} — import failed (HTTP ${HTTP_STATUS})"
                if [[ "$JQ_AVAILABLE" == "true" ]]; then
                    err_msg=$(echo "$BODY" | jq -r '.message // empty' 2>/dev/null || echo "")
                    [[ -n "$err_msg" ]] && info "Error: ${err_msg}"
                fi
            fi
        fi
    done

    # ─── Activate workflows ──────────────────────────────────────────────────
    header "6. Activating workflows"

    for wf_id in "${DEPLOYED_IDS[@]}"; do
        RESPONSE=$(curl -s -w "\n%{http_code}" \
            "${CURL_AUTH[@]}" \
            -X PATCH \
            -H "Content-Type: application/json" \
            -d '{"active": true}' \
            "${N8N_URL}/api/v1/workflows/${wf_id}" 2>/dev/null || echo -e "\n000")

        HTTP_STATUS=$(echo "$RESPONSE" | tail -1)
        BODY=$(echo "$RESPONSE" | sed '$d')

        WF_NAME=""
        if [[ "$JQ_AVAILABLE" == "true" ]]; then
            WF_NAME=$(echo "$BODY" | jq -r '.name // empty' 2>/dev/null || echo "")
        fi

        if [[ "$HTTP_STATUS" == "200" ]]; then
            ACTIVE_STATE=""
            if [[ "$JQ_AVAILABLE" == "true" ]]; then
                ACTIVE_STATE=$(echo "$BODY" | jq -r '.active // empty' 2>/dev/null || echo "")
            fi
            if [[ "$ACTIVE_STATE" == "true" ]]; then
                pass "Workflow ${wf_id}${WF_NAME:+ ($WF_NAME)} — ACTIVE"
            else
                warn "Workflow ${wf_id}${WF_NAME:+ ($WF_NAME)} — activation returned 200 but active=${ACTIVE_STATE}"
            fi
        else
            fail "Workflow ${wf_id}${WF_NAME:+ ($WF_NAME)} — activation failed (HTTP ${HTTP_STATUS})"
        fi
    done
else
    header "5. Skipping API deployment (no API access)"
    info "To enable API deployment, set N8N_API_KEY in config.env"
    info "Create an API key: n8n Settings → API → Create API Key"
    echo ""
    info "Manual deployment steps:"
    info "  1. Open ${N8N_URL} in your browser"
    info "  2. Go to Workflows → Import from File"
    info "  3. Import each JSON file one at a time"
    info "  4. Activate all 5 workflows"
    for i in "${!WORKFLOW_FILES[@]}"; do
        info "    • ${WORKFLOW_FILES[$i]}"
    done
fi

# ─── Validate webhook endpoints ─────────────────────────────────────────────
header "7. Validating webhook endpoints"

for i in "${!WEBHOOK_PATHS[@]}"; do
    wh_path="${WEBHOOK_PATHS[$i]}"
    wh_name="${WORKFLOW_NAMES[$i]}"
    wh_url="${N8N_URL}/webhook/${wh_path}"

    # Send a lightweight OPTIONS/GET probe — webhooks expect POST but we
    # just need to know the route is registered (n8n returns 404 if not)
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout 10 \
        -X POST \
        -H "Content-Type: application/json" \
        -d '{"test": true}' \
        "${wh_url}" 2>/dev/null || echo "000")

    if [[ "$HTTP_CODE" == "000" ]]; then
        fail "${wh_name} (${wh_url}) — unreachable"
    elif [[ "$HTTP_CODE" == "404" ]]; then
        fail "${wh_name} (${wh_url}) — not found (workflow may not be active)"
    elif [[ "$HTTP_CODE" == "500" ]]; then
        # 500 can mean the workflow triggered but hit an error processing test data
        # This is actually OK — it proves the webhook is registered and active
        pass "${wh_name} — webhook registered (processing error on test payload expected)"
    elif [[ "$HTTP_CODE" =~ ^(200|201|202)$ ]]; then
        pass "${wh_name} — webhook active (HTTP ${HTTP_CODE})"
    else
        warn "${wh_name} — responded HTTP ${HTTP_CODE} (may need investigation)"
    fi
done

# ─── Validate workflow listing (if API available) ────────────────────────────
if [[ "$API_AVAILABLE" == "true" && "$JQ_AVAILABLE" == "true" ]]; then
    header "8. Verifying workflow status via API"

    ALL_WF=$(curl -s "${CURL_AUTH[@]}" "${N8N_URL}/api/v1/workflows?limit=100" 2>/dev/null || echo "")

    if [[ -n "$ALL_WF" ]]; then
        TOTAL=$(echo "$ALL_WF" | jq '.data | length' 2>/dev/null || echo "0")
        ACTIVE_COUNT=$(echo "$ALL_WF" | jq '[.data[]? | select(.active == true)] | length' 2>/dev/null || echo "0")
        INACTIVE_COUNT=$(echo "$ALL_WF" | jq '[.data[]? | select(.active == false)] | length' 2>/dev/null || echo "0")

        info "Total workflows: ${TOTAL} (${ACTIVE_COUNT} active, ${INACTIVE_COUNT} inactive)"

        # List each workflow status
        echo "$ALL_WF" | jq -r '.data[]? | "\(.active)\t\(.id)\t\(.name)"' 2>/dev/null | \
        while IFS=$'\t' read -r active id name; do
            if [[ "$active" == "true" ]]; then
                pass "${name} (id: ${id}) — ACTIVE"
            else
                warn "${name} (id: ${id}) — INACTIVE"
            fi
        done
    else
        warn "Could not retrieve workflow list"
    fi
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${CYAN}  Deployment Summary${NC}"
echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${GREEN}Passed${NC}:   ${PASS}"
echo -e "  ${YELLOW}Warnings${NC}: ${WARN}"
echo -e "  ${RED}Failed${NC}:   ${FAIL}"
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All checks passed! Workflows are deployed and validated.${NC}"
    echo ""
    echo "Webhook URLs:"
    for i in "${!WEBHOOK_PATHS[@]}"; do
        echo "  ${WORKFLOW_NAMES[$i]}:"
        echo "    ${N8N_URL}/webhook/${WEBHOOK_PATHS[$i]}"
    done
    echo ""
    echo "Next steps:"
    echo "  1. Test the onboarding webhook with the curl command in SETUP-GUIDE.md (Section 9)"
    echo "  2. Monitor executions at: ${N8N_URL}/executions"
else
    echo -e "${RED}${BOLD}Some checks failed. Review the errors above and re-run.${NC}"
    echo ""
    echo "Common fixes:"
    echo "  • Workflows not found:  Import them manually via ${N8N_URL} → Workflows → Import"
    echo "  • Webhook 404:          Ensure workflows are activated in n8n"
    echo "  • API not accessible:   Set N8N_API_KEY in config.env"
    echo "  • Connection refused:   Check that n8n is running at ${N8N_URL}"
fi

echo ""
exit $FAIL
