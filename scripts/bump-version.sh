#!/bin/bash
# Auto version bumping script for projects with Claude Code integration
# Usage: ./scripts/bump-version.sh [OPTIONS] <major|minor|patch>

set -e

# Find project root (parent of .git directory)
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
VERSION_FILE="$PROJECT_ROOT/VERSION"
CHANGELOG_FILE="$PROJECT_ROOT/.meta/changelog.md"
CHANGELOGS_DIR="$PROJECT_ROOT/.meta/changelogs"

# Check if VERSION file exists
if [[ ! -f "$VERSION_FILE" ]]; then
    echo "Error: VERSION file not found at $VERSION_FILE"
    echo "Make sure you're in a project with version management infrastructure."
    exit 1
fi

# Ensure changelogs directory exists
mkdir -p "$CHANGELOGS_DIR"

# Help function
show_usage() {
    cat << 'EOF'
Usage: scripts/bump-version.sh [OPTIONS] <major|minor|patch>

Auto version bumping script for projects with Claude Code integration.

ARGUMENTS:
  major|minor|patch    Version bump type (required)

OPTIONS:
  -y, --yes                    Auto-confirm without prompting
  -c, --changelog-file FILE    Read changelog from file instead of stdin
  -h, --help                  Show this help message

INTERACTIVE MODE (default):
  scripts/bump-version.sh minor
  - Shows instructions for Claude Code changelog generation
  - Waits for changelog paste via stdin (Ctrl+D to finish)
  - Asks for confirmation before proceeding

NON-INTERACTIVE MODE:
  scripts/bump-version.sh --yes --changelog-file /path/to/changelog.txt patch
  - Reads changelog from file
  - Auto-confirms all prompts

EXAMPLES:
  # Interactive mode (current behavior)
  scripts/bump-version.sh minor

  # Full automation
  scripts/bump-version.sh --yes --changelog-file /tmp/my-changelog.md patch

  # Auto-confirm but manual changelog paste
  scripts/bump-version.sh --yes minor

  # Read from file but confirm manually
  scripts/bump-version.sh --changelog-file /tmp/changelog.md patch

CHANGELOG FORMAT:
  The changelog file/input must contain two sections:

  ## BULLETS
  - Brief bullet point 1
  - Brief bullet point 2

  ## DETAILED ANALYSIS
  [Full detailed analysis with context, explanations, workflow, impact]

NOTE:
  To manually write changelogs, edit VERSION and .meta/changelog.md directly.
  This script integrates with Claude Code for high-quality changelog generation.
EOF
}

# Default values
BUMP_TYPE=""
AUTO_CONFIRM=false
CHANGELOG_INPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_CONFIRM=true
            shift
            ;;
        -c|--changelog-file)
            if [[ -z "$2" ]] || [[ "$2" == -* ]]; then
                echo "Error: --changelog-file requires a file path"
                exit 1
            fi
            CHANGELOG_INPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        major|minor|patch)
            if [[ -n "$BUMP_TYPE" ]]; then
                echo "Error: Multiple bump types specified"
                exit 1
            fi
            BUMP_TYPE="$1"
            shift
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo ""
            show_usage
            exit 1
            ;;
    esac
done

# Validate required argument
if [[ -z "$BUMP_TYPE" ]]; then
    echo "Error: Bump type required (major|minor|patch)"
    echo ""
    show_usage
    exit 1
fi

# Read current version
CURRENT_VERSION=$(cat "$VERSION_FILE")
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Calculate new version
case $BUMP_TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Version Bump: $CURRENT_VERSION → $NEW_VERSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get changed files
STAGED_FILES=$(cd "$PROJECT_ROOT" && git diff --cached --name-only 2>/dev/null || echo "")
UNSTAGED_FILES=$(cd "$PROJECT_ROOT" && git diff --name-only 2>/dev/null || echo "")
ALL_CHANGED_FILES=$(echo -e "$STAGED_FILES\n$UNSTAGED_FILES" | sort -u | grep -v '^$')

if [[ -z "$ALL_CHANGED_FILES" ]]; then
    echo "⚠️  No changed files detected"
    echo "Make sure you have staged or modified files"
    exit 1
fi

echo "📋 Changed files:"
echo "$ALL_CHANGED_FILES" | while read file; do
    echo "  • $file"
done
echo ""

# Create temp file with diff
TEMP_DIFF="/tmp/project-v${NEW_VERSION}-diff.txt"
cd "$PROJECT_ROOT"

echo "=== Project Version $NEW_VERSION Changes ===" > "$TEMP_DIFF"
echo "" >> "$TEMP_DIFF"
echo "Changed Files:" >> "$TEMP_DIFF"
echo "$ALL_CHANGED_FILES" >> "$TEMP_DIFF"
echo "" >> "$TEMP_DIFF"
echo "=== Git Diff (Staged) ===" >> "$TEMP_DIFF"
git diff --cached >> "$TEMP_DIFF" 2>/dev/null || true
echo "" >> "$TEMP_DIFF"
echo "=== Git Diff (Unstaged) ===" >> "$TEMP_DIFF"
git diff >> "$TEMP_DIFF" 2>/dev/null || true

echo "✅ Diff saved to: $TEMP_DIFF"
echo ""

# Read changelog response
if [[ -n "$CHANGELOG_INPUT_FILE" ]]; then
    # Non-interactive: read from file
    # Resolve to absolute path
    CHANGELOG_INPUT_FILE=$(realpath "$CHANGELOG_INPUT_FILE" 2>/dev/null) || {
        echo "Error: Cannot resolve changelog file path: $CHANGELOG_INPUT_FILE"
        exit 1
    }

    if [[ ! -f "$CHANGELOG_INPUT_FILE" ]]; then
        echo "Error: Changelog file not found: $CHANGELOG_INPUT_FILE"
        exit 1
    fi

    if [[ ! -r "$CHANGELOG_INPUT_FILE" ]]; then
        echo "Error: Cannot read changelog file: $CHANGELOG_INPUT_FILE"
        echo "Check file permissions"
        exit 1
    fi

    FULL_RESPONSE=$(cat "$CHANGELOG_INPUT_FILE")
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Reading Changelog from File"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "File: $CHANGELOG_INPUT_FILE"
    echo ""
else
    # Interactive: read from stdin
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Generate Changelog with Claude Code"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "In this Claude Code session, ask:"
    echo ""
    echo "  \"Generate a changelog for $TEMP_DIFF in the following format:"
    echo ""
    echo "  ## BULLETS"
    echo "  - Brief bullet point 1"
    echo "  - Brief bullet point 2"
    echo "  ..."
    echo ""
    echo "  ## DETAILED ANALYSIS"
    echo "  [Full detailed analysis with context, explanations, workflow, impact]\""
    echo ""
    echo "Paste the full response below (press Ctrl+D when done):"
    echo ""

    FULL_RESPONSE=$(cat)
fi

if [[ -z "$FULL_RESPONSE" ]]; then
    if [[ -n "$CHANGELOG_INPUT_FILE" ]]; then
        echo "Error: Changelog file is empty: $CHANGELOG_INPUT_FILE"
    else
        echo "Error: No response provided"
    fi
    exit 1
fi

# Validate required sections exist
if ! echo "$FULL_RESPONSE" | grep -q "## BULLETS"; then
    if [[ -n "$CHANGELOG_INPUT_FILE" ]]; then
        echo "Error: Changelog file missing '## BULLETS' section"
        echo "File: $CHANGELOG_INPUT_FILE"
    else
        echo "Warning: Missing '## BULLETS' section in response"
    fi
    echo ""
    echo "Expected format:"
    echo "  ## BULLETS"
    echo "  - point 1"
    echo "  ..."
    echo "  ## DETAILED ANALYSIS"
    echo "  [analysis]"
    exit 1
fi

echo ""
echo "✅ Response captured"
echo ""

# Extract bullets section (between ## BULLETS and ## DETAILED ANALYSIS)
SUMMARY=$(echo "$FULL_RESPONSE" | awk '/## BULLETS/,/## DETAILED ANALYSIS/' | sed '1d;$d' | sed '/^$/d')

# Extract detailed analysis section (after ## DETAILED ANALYSIS)
DETAILED_ANALYSIS=$(echo "$FULL_RESPONSE" | awk '/## DETAILED ANALYSIS/,0' | sed '1d' | sed 's/^[[:space:]]*//')

# Validate extraction
if [[ -z "$SUMMARY" ]]; then
    echo "⚠️  Warning: Could not extract BULLETS section"
    echo "Using full response as summary"
    SUMMARY="$FULL_RESPONSE"
    DETAILED_ANALYSIS="$FULL_RESPONSE"
fi

if [[ -z "$DETAILED_ANALYSIS" ]]; then
    echo "⚠️  Warning: Could not extract DETAILED ANALYSIS section"
    echo "Using summary as detailed analysis"
    DETAILED_ANALYSIS="$SUMMARY"
fi

echo "Extracted bullet points:"
echo "$SUMMARY"
echo ""

# Changelog accuracy verification
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Changelog Accuracy Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Changed files in this commit:"
echo "$ALL_CHANGED_FILES" | while read file; do
    echo "  • $file"
done
echo ""
FILE_COUNT=$(echo "$ALL_CHANGED_FILES" | grep -v '^$' | wc -l | tr -d ' ')
echo "Total: $FILE_COUNT file(s) changed"
echo ""
echo "⚠️  VERIFY: Does your changelog accurately describe these changes?"
echo "   ✓ All mentioned files exist or were deleted as claimed"
echo "   ✓ File counts match actual files created/modified"
echo "   ✓ Version numbers are accurate"
echo "   ✓ Architectural decisions reflect final state (not initial plan)"
echo ""

if [[ "$AUTO_CONFIRM" = true ]]; then
    echo "Skipping changelog verification (--yes flag enabled)"
    echo "⚠️  Ensure changelog was verified before running with --yes"
    echo ""
else
    read -p "Changelog is accurate? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "❌ Aborted. Fix changelog and try again."
        echo ""
        echo "Common issues to check:"
        echo "  - Files mentioned that don't exist (deleted during fixes)"
        echo "  - File counts don't match actual changes"
        echo "  - Description based on initial plan, not final state"
        exit 1
    fi
    echo ""
fi

# Final confirmation
if [[ "$AUTO_CONFIRM" = true ]]; then
    echo "Auto-confirming version bump to $NEW_VERSION (--yes flag enabled)"
    echo ""
else
    read -p "Proceed with version bump to $NEW_VERSION? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Update VERSION file
echo "$NEW_VERSION" > "$VERSION_FILE"

# Get date
DATE=$(date +%Y-%m-%d)
BUMP_TYPE_CAPITALIZED=$(echo $BUMP_TYPE | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

# Create detailed changelog file
DETAILED_CHANGELOG="$CHANGELOGS_DIR/$NEW_VERSION.md"
cat > "$DETAILED_CHANGELOG" << EOF
# Version $NEW_VERSION - $DATE

## Type
$BUMP_TYPE_CAPITALIZED

$DETAILED_ANALYSIS

## Changed Files
EOF

# Add changed files to detailed changelog
if [[ -n "$ALL_CHANGED_FILES" ]]; then
    echo "$ALL_CHANGED_FILES" | while read file; do
        echo "- \`$file\`" >> "$DETAILED_CHANGELOG"
    done
else
    echo "(No changed files detected)" >> "$DETAILED_CHANGELOG"
fi

# Format summary for main changelog
# If not already bulleted, add bullets
if [[ ! "$SUMMARY" =~ ^- ]]; then
    FORMATTED_SUMMARY="- $SUMMARY"
else
    FORMATTED_SUMMARY="$SUMMARY"
fi

# Create brief entry for main changelog
TEMP_ENTRY="/tmp/changelog-entry-$NEW_VERSION.txt"
cat > "$TEMP_ENTRY" << EOF
## [$NEW_VERSION] - $DATE

### $BUMP_TYPE_CAPITALIZED
$FORMATTED_SUMMARY

**[Full details →](changelogs/$NEW_VERSION.md)**

EOF

# Insert into main changelog (before first version entry)
# Try to insert before first version entry (## [X.Y.Z])
if grep -q "^## \[" "$CHANGELOG_FILE"; then
    # Insert before first version entry
    awk -v temp="$TEMP_ENTRY" '
    /^## \[/ && !inserted {
        while ((getline line < temp) > 0) {
            print line
        }
        close(temp)
        inserted=1
    }
    {print}
    ' "$CHANGELOG_FILE" > "$CHANGELOG_FILE.tmp"
    mv "$CHANGELOG_FILE.tmp" "$CHANGELOG_FILE"
else
    # Fallback: append to end if no version entries yet
    cat "$TEMP_ENTRY" >> "$CHANGELOG_FILE"
fi

# Clean up temp file
rm -f "$TEMP_ENTRY"

echo ""
echo "✅ Version bumped to $NEW_VERSION"
echo "✅ Changelog updated: $CHANGELOG_FILE"
echo "✅ Detailed changelog: $DETAILED_CHANGELOG"
echo ""
echo "Next steps:"
echo "  git add VERSION .meta/"
echo "  git commit -m \"[$BUMP_TYPE_CAPITALIZED] <brief description>\""
echo "  git push origin main"
echo ""
