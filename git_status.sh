#!/bin/sh

# Config Datei
CONFIG_FILE="${1:-repos.conf}"

# Datumsvariablen
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
THIS_WEEK_START=$(date -d "last monday" +%Y-%m-%d)
LAST_WEEK_START=$(date -d "last monday - 1 week" +%Y-%m-%d)
LAST_WEEK_END=$(date -d "last sunday" +%Y-%m-%d)
THIS_MONTH_START=$(date +%Y-%m-01)
LAST_MONTH_START=$(date -d "$(date +%Y-%m-01) -1 month" +%Y-%m-%d)
LAST_MONTH_END=$(date -d "$(date +%Y-%m-01) -1 day" +%Y-%m-%d)
THIS_YEAR_START=$(date +%Y-01-01)
LAST_YEAR_START=$(date -d "$(date +%Y-01-01) -1 year" +%Y-%m-%d)
LAST_YEAR_END=$(date -d "$(date +%Y-01-01) -1 day" +%Y-%m-%d)

echo "=== START_REPORT ==="
echo "META|DATE|$TODAY"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file '$CONFIG_FILE' not found."
    exit 1
fi

analyze_repo() {
    repo_path=$1; start_date=$2; end_date=$3; period_name=$4; repo_name=$5; git_user=$6

    cmd="git log --all --author=\"$git_user\" --since=\"$start_date 00:00:00\" -i"
    if [ "$end_date" != "" ]; then cmd="$cmd --until=\"$end_date 23:59:59\""; fi

    # Stats berechnen
    stats=$(eval "$cmd --numstat --format=''" | awk '{ if ($1 != "-") { a+=$1; d+=$2; f++ } } END { printf "%d|%d|%d", f, a, d }')
    
    # Branches parsen
    branches=$(eval "$cmd --format='%D'" | sed 's/HEAD -> //g' | tr ',' '\n' | sed 's/^[ \t]*//' | grep -v "origin/" | grep -v "tag:" | sort -u | tr '\n' ',' | sed 's/,$//')

    files=$(echo "$stats" | cut -d'|' -f1)
    added=$(echo "$stats" | cut -d'|' -f2)
    deleted=$(echo "$stats" | cut -d'|' -f3)

    # Nullen erzwingen (sh kompatibel)
    if [ -z "$files" ] || [ "$files" -eq 0 ]; then return; fi 
    if [ -z "$added" ]; then added=0; fi
    if [ -z "$deleted" ]; then deleted=0; fi
    if [ -z "$branches" ]; then branches="NONE"; fi

    echo "REPO|$repo_name|$period_name|$files|$added|$deleted"
    echo "BRANCHES|$repo_name|$period_name|$branches"
}

TEMP_FILE="/tmp/git_stats_$(date +%s).tmp"
touch "$TEMP_FILE"

# Config lesen
grep -vE '^\s*#' "$CONFIG_FILE" | grep -vE '^\s*$' | while read -r raw_path; do
    repo_path=$(eval echo "$raw_path")
    repo_name=$(basename "$repo_path")

    if [ -d "$repo_path/.git" ]; then
        echo "DEBUG: Checking $repo_name" >&2
        (
            cd "$repo_path" || exit
            LOCAL_USER=$(git config user.name)
            if [ -z "$LOCAL_USER" ]; then LOCAL_USER=$(git config --global user.name); fi
            
            # Kurzer Check ob überhaupt was los war dieses Jahr
            check=$(git log --all --author="$LOCAL_USER" --since="$THIS_YEAR_START" -i --oneline | head -n 1)
            
            if [ "$check" != "" ]; then
                analyze_repo "$repo_path" "$TODAY" "" "TODAY" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$YESTERDAY" "$YESTERDAY" "YESTERDAY" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$THIS_WEEK_START" "" "THIS_WEEK" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$LAST_WEEK_START" "$LAST_WEEK_END" "LAST_WEEK" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$THIS_MONTH_START" "" "THIS_MONTH" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$LAST_MONTH_START" "$LAST_MONTH_END" "LAST_MONTH" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$THIS_YEAR_START" "" "THIS_YEAR" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_path" "$LAST_YEAR_START" "$LAST_YEAR_END" "LAST_YEAR" "$repo_name" "$LOCAL_USER"
            fi
        ) >> "$TEMP_FILE"
    fi
done

cat "$TEMP_FILE"

# Totals berechnen (AWK Syntax vereinfacht)
awk -F'|' '
BEGIN { OFS="|" }
/^REPO/ {
    p=$3; 
    tf[p]+=$4; 
    ta[p]+=$5; 
    td[p]+=$6;
}
END {
    # Manuelle Liste statt split() um Shell-Probleme zu vermeiden
    print_total("TODAY", tf["TODAY"], ta["TODAY"], td["TODAY"])
    print_total("YESTERDAY", tf["YESTERDAY"], ta["YESTERDAY"], td["YESTERDAY"])
    print_total("THIS_WEEK", tf["THIS_WEEK"], ta["THIS_WEEK"], td["THIS_WEEK"])
    print_total("LAST_WEEK", tf["LAST_WEEK"], ta["LAST_WEEK"], td["LAST_WEEK"])
    print_total("THIS_MONTH", tf["THIS_MONTH"], ta["THIS_MONTH"], td["THIS_MONTH"])
    print_total("LAST_MONTH", tf["LAST_MONTH"], ta["LAST_MONTH"], td["LAST_MONTH"])
    print_total("THIS_YEAR", tf["THIS_YEAR"], ta["THIS_YEAR"], td["THIS_YEAR"])
    print_total("LAST_YEAR", tf["LAST_YEAR"], ta["LAST_YEAR"], td["LAST_YEAR"])
}

function print_total(name, f, a, d) {
    if (f == "") f=0;
    if (a == "") a=0;
    if (d == "") d=0;
    print "TOTAL", "ALL", name, f, a, d
}' "$TEMP_FILE"

rm "$TEMP_FILE"
echo "=== END_REPORT ==="

