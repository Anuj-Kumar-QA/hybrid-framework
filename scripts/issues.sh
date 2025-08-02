#!/bin/bash
set -euo pipefail

# === CONFIGURATION ===
ASSIGNEE="${1:-$(gh api user --jq '.login')}"
LABEL_FILTER="${2:-}"
ISSUES_DIR=".github/issues"

# === COLORS & ICONS ===
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
NC='\033[0m'

ICON_SUCCESS="🟢"
ICON_SKIPPED="⚪"
ICON_FAILED="🔴"

declare -A known_labels=()
declare -a existing_labels_lower=()

# === FUNCTIONS ===

print_status_line() {
  local title=$1 icon=$2 color_code=$3 status=$4
  printf "%b✔ %s → %s %s%b\n" "$color_code" "$title" "$icon" "$status" "$NC"
}

print_progress_bar() {
  local current_count=$1 total_count=$2 width=30
  if (( total_count > 0 )); then
    local percentage=$(( current_count * 100 / total_count ))
    local filled=$(( (percentage * width + 50) / 100 ))
    local empty=$((width - filled))
    local bar=$(printf "%0.s█" $(seq 1 $filled))
    local spaces=$(printf "%0.s░" $(seq 1 $empty))
    echo -e "[${bar}${spaces}] ${percentage}%% ($current_count/$total_count)"
  fi
}

normalize_title() {
  echo "$1" | perl -CSDA -pe 's/\p{So}//g' | sed 's/[^[:alnum:]]//g' | tr '[:upper:]' '[:lower:]'
}

cache_existing_labels() {
  mapfile -t existing_labels_lower < <(gh label list --limit 1000 | awk '{print tolower($1)}')
}

create_label_if_needed() {
  local label_name="$1"
  label_name=$(echo "$label_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '"')

  if [[ -n "${known_labels[$label_name]:-}" ]]; then return 0; fi

  local lower_label=$(echo "$label_name" | tr '[:upper:]' '[:lower:]')
  if printf "%s\n" "${existing_labels_lower[@]}" | grep -qx "$lower_label"; then
    known_labels[$label_name]=1
    return 0
  fi

  if gh label create "$label_name" --color "$(echo "$label_name" | sha256sum | head -c 6)" &>/dev/null; then
    known_labels[$label_name]=1
    existing_labels_lower+=("$lower_label")
    return 0
  fi

  return 1
}

create_issue_from_file() {
  local file="$1"
  local raw_title=$(awk -F': ' '/^title:/ {print $2; exit}' "$file")
  local clean_title=$(echo "$raw_title" | sed 's/^"//;s/"$//' | xargs)
  local compare_title=$(normalize_title "$clean_title")

  local existing_titles
  mapfile -t existing_titles < <(gh issue list --limit 1000 --json title --jq '.[].title')

  for title in "${existing_titles[@]}"; do
    if [[ "$(normalize_title "$title")" == "$compare_title" ]]; then
      print_status_line "$clean_title" "$ICON_SKIPPED" "$WHITE" "Already exists"
      return 1
    fi
  done

  local labels=$(awk -F': ' '/^labels:/ {print $2; exit}' "$file" | tr -d '[]"' | tr ',' '\n' | xargs -n1)

  # Check label filter match
  if [[ -n "$LABEL_FILTER" ]]; then
    local found_match=0
    for label in $labels; do
      if [[ "${label,,}" == "${LABEL_FILTER,,}" ]]; then
        found_match=1
        break
      fi
    done
    if [[ $found_match -eq 0 ]]; then
      return 1
    fi
  fi

  local milestone=$(awk -F': ' '/^milestone:/ {print $2; exit}' "$file" | tr -d '"')
  local milestone_arg=()
  if [[ -n "$milestone" ]]; then
    milestone_arg=("--milestone" "$milestone")
  fi

  local body=$(awk '/^---$/ {count++; next} count >= 2 {print}' "$file")

  local label_args=()
  for label in $labels; do
    if create_label_if_needed "$label"; then
      label_args+=("-l" "$label")
    fi
  done

  if issue_url=$(gh issue create -t "$clean_title" -b "$body" --assignee "$ASSIGNEE" "${label_args[@]}" "${milestone_arg[@]}" 2>/dev/null); then
    print_status_line "$clean_title" "$ICON_SUCCESS" "$GREEN" "Created"
    return 0
  else
    print_status_line "$clean_title" "$ICON_FAILED" "$RED" "Failed"
    return 2
  fi
}

main() {
  if [[ ! -d "$ISSUES_DIR" ]]; then
    echo -e "${RED}❌ Directory '$ISSUES_DIR' not found.${NC}"
    exit 1
  fi

  cache_existing_labels

  echo -e "\n🚀 Starting issue creation from '$ISSUES_DIR'..."
  local created=0 skipped=0 failed=0 total=0
  local current_count=0

  local file_list=("$ISSUES_DIR"/*.md)
  for file in "${file_list[@]}"; do
    [[ -f "$file" ]] || continue
    total=$((total + 1))
  done

  for file in "${file_list[@]}"; do
    [[ -f "$file" ]] || continue
    current_count=$((current_count + 1))
    if create_issue_from_file "$file"; then
      created=$((created + 1))
    else
      status=$?
      if [[ $status -eq 1 ]]; then
        skipped=$((skipped + 1))
      else
        failed=$((failed + 1))
      fi
    fi
  done

  echo -e "📊 Issue Creation Summary:"
  print_progress_bar "$total" "$total"
  echo -e "  ${GREEN}Created: $created${NC}"
  echo -e "  ${WHITE}Skipped: $skipped${NC}"
  [[ $failed -gt 0 ]] && echo -e "  ${RED}Failed: $failed${NC}"
}

main "$@"
