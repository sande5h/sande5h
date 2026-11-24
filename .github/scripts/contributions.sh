#!/usr/bin/env bash
# Draws dist/contributions.svg and dist/contributions-dark.svg with the
# contribution count from the last year and the total since the first year.
set -euo pipefail
user="$1"; out="${2:-dist}"; mkdir -p "$out"

q() { gh api graphql -f query="$1" --jq "$2"; }

year_count=$(q "{user(login:\"$user\"){contributionsCollection{contributionCalendar{totalContributions}}}}" \
  '.data.user.contributionsCollection.contributionCalendar.totalContributions')
years=$(q "{user(login:\"$user\"){contributionsCollection{contributionYears}}}" \
  '.data.user.contributionsCollection.contributionYears[]')

total=0; first=9999
for y in $years; do
  n=$(q "{user(login:\"$user\"){contributionsCollection(from:\"$y-01-01T00:00:00Z\",to:\"$y-12-31T23:59:59Z\"){contributionCalendar{totalContributions}}}}" \
    '.data.user.contributionsCollection.contributionCalendar.totalContributions')
  total=$((total + n)); [ "$y" -lt "$first" ] && first=$y
done

fmt() { printf "%'d" "$1" 2>/dev/null || echo "$1"; }
export LC_NUMERIC=en_US.UTF-8
a=$(fmt "$year_count"); b=$(fmt "$total")

card() { # $1 file  $2 background  $3 border  $4 text  $5 muted  $6 green
cat > "$1" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="480" height="110" viewBox="0 0 480 110" role="img" aria-label="$a contributions in the last year, $b in total since $first">
  <style>text{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","Noto Sans",Helvetica,Arial,sans-serif}</style>
  <rect x="0.5" y="0.5" width="479" height="109" rx="8" fill="$2" stroke="$3"/>
  <text x="28" y="56" font-size="34" font-weight="600" fill="$6">$a</text>
  <text x="28" y="84" font-size="14" fill="$5">contributions in the last year</text>
  <line x1="240" y1="24" x2="240" y2="86" stroke="$3"/>
  <text x="264" y="56" font-size="34" font-weight="600" fill="$4">$b</text>
  <text x="264" y="84" font-size="14" fill="$5">in total since $first</text>
</svg>
SVG
}
card "$out/contributions.svg"      "#ffffff" "#d1d9e0" "#1f2328" "#59636e" "#1a7f37"
card "$out/contributions-dark.svg" "#0d1117" "#3d444d" "#e6edf3" "#9198a1" "#3fb950"
echo "last year: $a  total: $b since $first"
