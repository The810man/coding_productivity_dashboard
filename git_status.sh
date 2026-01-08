#!/bin/sh

CONFIG_FILE="${1:-repos.conf}"
THRESHOLD="${2:-0}"

# Datums-Variablen
TODAY=$(date +%Y-%m-%d)
# ... (Rest der Datumslogik, hier gekürzt für Übersicht, lass deine drin oder kopiere von oben) ...
# Wir brauchen aber zwingend diese Variablen, also hier nochmal kurz:
THIS_WEEK_START=$(date -d "last monday" +%Y-%m-%d)
THIS_MONTH_START=$(date +%Y-%m-01)
THIS_YEAR_START=$(date +%Y-01-01)
HEATMAP_START=$(date -d "365 days ago" +%Y-%m-%d)

echo "=== START_REPORT ==="
echo "META|DATE|$TODAY"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file '$CONFIG_FILE' missing!"
    exit 1
fi

analyze_repo() {
    repo_path=$1; start=$2; end=$3; period=$4; name=$5; user=$6
    
    # Excludes definieren
    excludes=":!*.json :!*.lock :!*.g.dart :!*.freezed.dart :!*.min.js :!*.png :!*.jpg :!*.ttf :!*.otf :!*podfile.lock :!*pubspec.lock :!*CMakeLists.txt :!*.html"
    
    # BASIS BEFEHL
    # --numstat muss direkt hier stehen, nicht erst im eval
    # WICHTIG: Pfade (excludes) müssen AM ENDE nach einem "--" stehen
    
    base_cmd="git log --all --author=\"$user\" --since=\"$start 00:00:00\" -i"
    if [ "$end" != "" ]; then base_cmd="$base_cmd --until=\"$end 23:59:59\""; fi

    # 1. STATS HOLEN
    # Hier bauen wir den String so zusammen: git log ... --numstat ... -- :!exclude
    stats_cmd="$base_cmd --numstat --format='' -- $excludes"
    
    stats=$(eval "$stats_cmd" | awk -v limit="$THRESHOLD" '{ 
        if ($1 != "-") {
            if (limit == 0 || $1 < limit) { a+=$1; d+=$2; f++ }
        }
    } END { printf "%d|%d|%d", f, a, d }')

    # 2. BRANCHES HOLEN
    # Hier brauchen wir kein --numstat, aber die Excludes schaden nicht (oder wir lassen sie weg für Performance)
    # Wir lassen sie weg, da Branches repo-weit sind, nicht file-spezifisch
    branches_cmd="$base_cmd --format='%D'"
    branches=$(eval "$branches_cmd" | sed 's/HEAD -> //g' | tr ',' '\n' | sed 's/^[ \t]*//' | grep -v "origin/" | grep -v "tag:" | sort -u | tr '\n' ',' | sed 's/,$//')

    files=$(echo "$stats" | cut -d'|' -f1)
    added=$(echo "$stats" | cut -d'|' -f2)
    deleted=$(echo "$stats" | cut -d'|' -f3)

    if [ -z "$files" ] || [ "$files" -eq 0 ]; then return; fi 
    if [ -z "$added" ]; then added=0; fi; if [ -z "$deleted" ]; then deleted=0; fi; if [ -z "$branches" ]; then branches="NONE"; fi

    echo "REPO|$name|$period|$files|$added|$deleted"
    echo "BRANCHES|$name|$period|$branches"
}


analyze_heatmap() {
    echo "DEBUG: Hole Heatmap für $2..." >&2
    git log --all --author="$3" --since="$HEATMAP_START" --format="%ad" --date=short | sort | uniq -c | while read count date; do
        echo "HEATMAP|$date|$count"
    done
}

TEMP_FILE="/tmp/git_stats_debug.tmp"
touch "$TEMP_FILE"

# Config lesen
grep -vE '^\s*#' "$CONFIG_FILE" | grep -vE '^\s*$' | while read -r raw_path; do
    repo_path=$(eval echo "$raw_path")
    repo_name=$(basename "$repo_path")

    if [ -d "$repo_path/.git" ]; then
        (
            cd "$repo_path" || exit
            
            # User Erkennung DEBUGGEN
            LOCAL_USER=$(git config user.name)
            GLOBAL_USER=$(git config --global user.name)
            
            if [ -z "$LOCAL_USER" ]; then 
                LOCAL_USER="$GLOBAL_USER"
                echo "DEBUG: Nutze Global User '$LOCAL_USER' für $repo_name" >&2
            else
                echo "DEBUG: Nutze Local User '$LOCAL_USER' für $repo_name" >&2
            fi
            
            # Test: Gibt es ÜBERHAUPT Commits dieses Jahr?
            check=$(git log --all --author="$LOCAL_USER" --since="$THIS_YEAR_START" -i --oneline | head -n 1)
            
            if [ "$check" != "" ]; then
                analyze_repo "$repo_path" "$TODAY" "" "TODAY" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$THIS_WEEK_START" "" "THIS_WEEK" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$THIS_MONTH_START" "" "THIS_MONTH" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$THIS_YEAR_START" "" "THIS_YEAR" "$repo_name" "$LOCAL_USER"
                analyze_heatmap "$repo_path" "$repo_name" "$LOCAL_USER"
            else
                echo "DEBUG: WARNUNG - Keine Commits von '$LOCAL_USER' in 2024/25 gefunden!" >&2
                # Fallback Versuch: Zeige den letzten Commit Author an
                last_author=$(git log -1 --format='%an')
                echo "DEBUG: Tipp: Der letzte Commit war von '$last_author'. Stimmt deine Git Config?" >&2
            fi
        ) >> "$TEMP_FILE"
    else
        echo "DEBUG: Pfad ist kein Git Repo: $repo_path" >&2
    fi
done

cat "$TEMP_FILE"

# Totals berechnen
awk -F'|' '
BEGIN { OFS="|" }
/^REPO/ { p=$3; tf[p]+=$4; ta[p]+=$5; td[p]+=$6; }
END {
    print_total("TODAY", tf["TODAY"], ta["TODAY"], td["TODAY"])
    print_total("THIS_WEEK", tf["THIS_WEEK"], ta["THIS_WEEK"], td["THIS_WEEK"])
    print_total("THIS_MONTH", tf["THIS_MONTH"], ta["THIS_MONTH"], td["THIS_MONTH"])
    print_total("THIS_YEAR", tf["THIS_YEAR"], ta["THIS_YEAR"], td["THIS_YEAR"])
}
function print_total(n, f, a, d) { print "TOTAL", "ALL", n, (f?f:0), (a?a:0), (d?d:0) }' "$TEMP_FILE"

# Heatmap Totals
echo "=== HEATMAP_TOTALS ==="
grep "^HEATMAP" "$TEMP_FILE" | awk -F'|' '{ dates[$2] += $3 } END { for (d in dates) print "HEATMAP_TOTAL|" d "|" dates[d] }' | sort

rm "$TEMP_FILE"
echo "=== END_REPORT ==="
