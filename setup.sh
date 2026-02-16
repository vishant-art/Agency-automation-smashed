#!/usr/bin/env bash
# =============================================================================
# Smashed Agency — UGC Script Engine Setup Script
# =============================================================================
# Replaces all placeholder values across n8n workflow JSON files using
# values from config.env.
#
# Usage:
#   1. cp config.env.example config.env
#   2. Fill in your values in config.env
#   3. bash setup.sh
#
# This script is idempotent — safe to run multiple times.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} Smashed Agency — Workflow Setup${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# --- Load config ---
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: config.env not found.${NC}"
    echo "  cp config.env.example config.env"
    echo "  Then fill in your values and run this script again."
    exit 1
fi

# Source the config file
set -a
source "$CONFIG_FILE"
set +a

# --- Validation ---
ERRORS=0

validate_required() {
    local var_name="$1"
    local var_value="${!var_name:-}"
    if [[ -z "$var_value" ]]; then
        echo -e "  ${RED}MISSING${NC}: $var_name"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "  ${GREEN}OK${NC}:      $var_name = ${var_value:0:20}..."
    fi
}

validate_optional() {
    local var_name="$1"
    local var_value="${!var_name:-}"
    if [[ -z "$var_value" ]]; then
        echo -e "  ${YELLOW}SKIP${NC}:    $var_name (optional, keeping default)"
    else
        echo -e "  ${GREEN}OK${NC}:      $var_name = ${var_value:0:20}..."
    fi
}

echo "Validating configuration..."
echo ""
echo "Required:"
validate_required "N8N_BASE_URL"
validate_required "AIRTABLE_CREDENTIAL_ID"
validate_required "OPENAI_CREDENTIAL_ID"
validate_required "SERPAPI_CREDENTIAL_ID"
validate_required "GOOGLE_SHEETS_CREDENTIAL_ID"
validate_required "GOOGLE_DRIVE_CREDENTIAL_ID"
validate_required "SLACK_CREDENTIAL_ID"
echo ""
echo "Optional:"
validate_optional "CLICKUP_CREDENTIAL_ID"
validate_optional "GOOGLE_SHEET_ID"
validate_optional "SLACK_CHANNEL_ID"
validate_optional "SLACK_PM_USER_ID"
validate_optional "CLICKUP_SPACE_ID"
validate_optional "CLICKUP_WORKSPACE_ID"
validate_optional "GOOGLE_DRIVE_CLIENTS_FOLDER_ID"
validate_optional "AIRTABLE_BASE_ID"
echo ""

if [[ $ERRORS -gt 0 ]]; then
    echo -e "${RED}Found $ERRORS missing required value(s). Please update config.env and try again.${NC}"
    exit 1
fi

# --- Replacement function ---
replace_in_files() {
    local placeholder="$1"
    local value="$2"
    local count=0

    if [[ -z "$value" ]]; then
        return 0
    fi

    for file in "$SCRIPT_DIR"/n8n-*.json; do
        if [[ -f "$file" ]]; then
            local matches
            matches=$(grep -c "$placeholder" "$file" 2>/dev/null || true)
            if [[ "$matches" -gt 0 ]]; then
                # Use a delimiter that won't appear in URLs or IDs
                sed -i "s|${placeholder}|${value}|g" "$file"
                count=$((count + matches))
            fi
        fi
    done

    if [[ $count -gt 0 ]]; then
        echo -e "  ${GREEN}Replaced${NC}: ${placeholder} → ${value:0:30}... (${count} occurrences)"
    fi
    return $count
}

# --- Apply replacements ---
echo -e "${CYAN}Applying replacements...${NC}"
echo ""
TOTAL=0

# Credential IDs (required)
replace_in_files "YOUR_AIRTABLE_CREDENTIAL_ID" "$AIRTABLE_CREDENTIAL_ID" || TOTAL=$((TOTAL + $?))
replace_in_files "YOUR_OPENAI_CREDENTIAL_ID" "$OPENAI_CREDENTIAL_ID" || TOTAL=$((TOTAL + $?))
replace_in_files "YOUR_SERPAPI_CREDENTIAL_ID" "$SERPAPI_CREDENTIAL_ID" || TOTAL=$((TOTAL + $?))
replace_in_files "YOUR_GOOGLE_SHEETS_CREDENTIAL_ID" "$GOOGLE_SHEETS_CREDENTIAL_ID" || TOTAL=$((TOTAL + $?))
replace_in_files "YOUR_GOOGLE_DRIVE_CREDENTIAL_ID" "$GOOGLE_DRIVE_CREDENTIAL_ID" || TOTAL=$((TOTAL + $?))
replace_in_files "YOUR_SLACK_CREDENTIAL_ID" "$SLACK_CREDENTIAL_ID" || TOTAL=$((TOTAL + $?))
replace_in_files "YOUR_CLICKUP_API_CREDENTIAL_ID" "${CLICKUP_CREDENTIAL_ID:-}" || TOTAL=$((TOTAL + $?))

# n8n Base URL
replace_in_files "YOUR_N8N_BASE_URL" "$N8N_BASE_URL" || TOTAL=$((TOTAL + $?))

# Optional: Google Sheet ID
if [[ -n "${GOOGLE_SHEET_ID:-}" ]]; then
    replace_in_files "1cB4wtyp0l0xwH2Ukw-U93eW9_Ix1lB6EroYs1GyDLCM" "$GOOGLE_SHEET_ID" || TOTAL=$((TOTAL + $?))
fi

# Optional: Slack Channel/User IDs
if [[ -n "${SLACK_CHANNEL_ID:-}" ]]; then
    replace_in_files "C07MN9QA1R7" "$SLACK_CHANNEL_ID" || TOTAL=$((TOTAL + $?))
fi
if [[ -n "${SLACK_PM_USER_ID:-}" ]]; then
    replace_in_files "U06P9F49BJT" "$SLACK_PM_USER_ID" || TOTAL=$((TOTAL + $?))
fi

# Optional: ClickUp IDs
if [[ -n "${CLICKUP_SPACE_ID:-}" ]]; then
    replace_in_files "90165772240" "$CLICKUP_SPACE_ID" || TOTAL=$((TOTAL + $?))
fi
if [[ -n "${CLICKUP_WORKSPACE_ID:-}" ]]; then
    replace_in_files "90161381822" "$CLICKUP_WORKSPACE_ID" || TOTAL=$((TOTAL + $?))
fi

# Optional: Google Drive folder
if [[ -n "${GOOGLE_DRIVE_CLIENTS_FOLDER_ID:-}" ]]; then
    replace_in_files "1tsbdVo92ECUyUCaCwvq1yGCRpA4uCDxT" "$GOOGLE_DRIVE_CLIENTS_FOLDER_ID" || TOTAL=$((TOTAL + $?))
fi

# Optional: Airtable Base ID
if [[ -n "${AIRTABLE_BASE_ID:-}" ]]; then
    replace_in_files "appvFxwZc9yU8o8pK" "$AIRTABLE_BASE_ID" || TOTAL=$((TOTAL + $?))
fi

echo ""

# --- Verify no remaining placeholders ---
echo -e "${CYAN}Checking for remaining placeholders...${NC}"
echo ""
REMAINING=0

check_placeholder() {
    local placeholder="$1"
    local count=0
    for file in "$SCRIPT_DIR"/n8n-*.json; do
        local matches
        matches=$(grep -c "$placeholder" "$file" 2>/dev/null || true)
        count=$((count + matches))
    done
    if [[ $count -gt 0 ]]; then
        echo -e "  ${YELLOW}WARNING${NC}: ${placeholder} still found (${count} occurrences)"
        REMAINING=$((REMAINING + count))
    fi
}

check_placeholder "YOUR_AIRTABLE_CREDENTIAL_ID"
check_placeholder "YOUR_OPENAI_CREDENTIAL_ID"
check_placeholder "YOUR_SERPAPI_CREDENTIAL_ID"
check_placeholder "YOUR_GOOGLE_SHEETS_CREDENTIAL_ID"
check_placeholder "YOUR_GOOGLE_DRIVE_CREDENTIAL_ID"
check_placeholder "YOUR_SLACK_CREDENTIAL_ID"
check_placeholder "YOUR_CLICKUP_API_CREDENTIAL_ID"
check_placeholder "YOUR_N8N_BASE_URL"

if [[ $REMAINING -eq 0 ]]; then
    echo -e "  ${GREEN}All placeholders replaced successfully!${NC}"
else
    echo ""
    echo -e "  ${YELLOW}${REMAINING} placeholder(s) remain. Check config.env for missing values.${NC}"
fi

echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} Setup Complete${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Import the workflow JSON files into n8n (Workflows → Import from File)"
echo "  2. Activate all 5 workflows in n8n"
echo "  3. Test with the curl commands in SETUP-GUIDE.md"
echo ""
