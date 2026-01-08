#!/bin/sh

# Konfiguration: Pfad als 1. Argument nehmen, sonst ".." (ein Ordner hoch)
if [ -z "$1" ]; then
    ROOT_DIR=".."
    # Info auf stderr ausgeben (damit es das Parsing nicht kaputt macht)
    echo "DEBUG: Kein Pfad angegeben. Suche in '$ROOT_DIR' (Elternordner)..." >&2
else
    ROOT_DIR="$1"
    echo "DEBUG: Suche in '$ROOT_DIR'..." >&2
fi

# Datumsberechnungen (Linux GNU Date)
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

# Funktion zum Sammeln der Stats
analyze_repo() {
    repo_path=$1
    start_date=$2
    end_date=$3
    period_name=$4
    repo_name=$5
    git_user=$6

    # Basis-Command (-i für case-insensitive User Suche)
    cmd="git log --all --author=\"$git_user\" --since=\"$start_date 00:00:00\" -i" 
    
    if [ "$end_date" != "" ]; then
        cmd="$cmd --until=\"$end_date 23:59:59\""
    fi

    # 1. Stats (Files, Added, Deleted) - Alles in einem awk Durchgang
    lines=$(eval "$cmd --numstat --format=''" | awk '{ if ($1 != "-") { add += $1; subs += $2; files++ } } END { printf "%d|%d|%d", files, add, subs }')
    
    # 2. Branches parsen (ref names säubern)
    branches=$(eval "$cmd --format='%D'" | sed 's/HEAD -> //g' | tr ',' '\n' | sed 's/^[ \t]*//' | grep -v "origin/" | grep -v "tag:" | sort -u | tr '\n' ',' | sed 's/,$//')

    files=$(echo "$lines" | cut -d'|' -f1)
    added=$(echo "$lines" | cut -d'|' -f2)
    deleted=$(echo "$lines" | cut -d'|' -f3)

    if [ -z "$added" ]; then added=0; fi
    if [ -z "$deleted" ]; then deleted=0; fi
    if [ -z "$files" ]; then files=0; fi
    if [ -z "$branches" ]; then branches="NONE"; fi

    if [ "$files" -gt 0 ]; then
        echo "REPO|$repo_name|$period_name|$files|$added|$deleted"
        echo "BRANCHES|$repo_name|$period_name|$branches"
    fi
}

TEMP_FILE="/tmp/git_stats_v3_$(date +%s).tmp"

# Repos finden: Wir suchen nach .git Ordnern
# maxdepth 3 erhöht, falls du Unterordner-Strukturen hast (z.B. Work/KundeA/Projekt)
find "$ROOT_DIR" -maxdepth 3 -name ".git" -type d 2>/dev/null | while read gitdir; do
    repo_root=$(dirname "$gitdir")
    repo_name=$(basename "$repo_root")
    
    # Debug Ausgabe auf stderr (sieht man im Terminal, landet aber nicht im Dart String)
    echo "DEBUG: Prüfe Repo: $repo_name" >&2

    (
        cd "$repo_root" || exit
        
        # User bestimmen (Lokal > Global)
        LOCAL_USER=$(git config user.name)
        if [ -z "$LOCAL_USER" ]; then
            LOCAL_USER=$(git config --global user.name)
        fi
        
        # Wenn gar kein User gefunden wurde, überspringen
        if [ -z "$LOCAL_USER" ]; then
             echo "DEBUG: WARNUNG - Kein Git User für $repo_name gefunden." >&2
        else
            # Performance Check
            active_check=$(git log --all --author="$LOCAL_USER" --since="$THIS_YEAR_START" -i --oneline | head -n 1)
            
            if [ "$active_check" != "" ]; then
                analyze_repo "$repo_root" "$TODAY" "" "TODAY" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_root" "$YESTERDAY" "$YESTERDAY" "YESTERDAY" "$repo_name" "$LOCAL_USER"
                
                analyze_repo "$repo_root" "$THIS_WEEK_START" "" "THIS_WEEK" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_root" "$LAST_WEEK_START" "$LAST_WEEK_END" "LAST_WEEK" "$repo_name" "$LOCAL_USER"
                
                analyze_repo "$repo_root" "$THIS_MONTH_START" "" "THIS_MONTH" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_root" "$LAST_MONTH_START" "$LAST_MONTH_END" "LAST_MONTH" "$repo_name" "$LOCAL_USER"
                
                analyze_repo "$repo_root" "$THIS_YEAR_START" "" "THIS_YEAR" "$repo_name" "$LOCAL_USER"
                analyze_repo "$repo_root" "$LAST_YEAR_START" "$LAST_YEAR_END" "LAST_YEAR" "$repo_name" "$LOCAL_USER"
            fi
        fi
    )
done > "$TEMP_FILE"

cat "$TEMP_FILE"

# Totals berechnen
awk -F'|' '
BEGIN { OFS="|" }
/^REPO/ {
    period=$3; files=$4; added=$5; deleted=$6
    t_files[period] += files
    t_added[period] += added
    t_deleted[period] += deleted
}
END {
    split("TODAY YESTERDAY THIS_WEEK LAST_WEEK THIS_MONTH LAST_MONTH THIS_YEAR LAST_YEAR", periods, " ")
    for (i=1; i<=8; i++) {
        p = periods[i]
        f = t_files[p] ? t_files[p] : 0
        a = t_added[p] ? t_added[p] : 0
        d = t_deleted[p] ? t_deleted[p] : 0
        print "TOTAL", "ALL", p, f, a, d
    }
}' "$TEMP_FILE"

rm "$TEMP_FILE"
echo "=== END_REPORT ==="

