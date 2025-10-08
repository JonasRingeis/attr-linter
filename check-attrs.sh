#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

team_alias="fti"
project_alias="xz"

exceptions="data-autotab data-int data-pinfo data-sheet-title data-value"

attr_matching=$(grep -EHnr \
  --exclude-dir='node_modules' \
  --exclude-dir="build" \
  --exclude-dir="cdk.out" \
  --exclude-dir="dist" \
  --exclude-dir=".git" \
  --exclude-dir="playwright-report" \
  --exclude-dir="coverage/" \
  --exclude-dir="test-report" \
  --exclude-dir="*snapshots*" \
  --exclude="*.json" \
  --exclude="tsconfig.tsbuildinfo" \
  --exclude="*.svg" \
  "data-[a-z0-9\-]+" ./*[!.sh] | grep -E -v "data-$team_alias-$project_alias-[a-z0-9\-]+")

contains() {
  [[ " $1 " =~ " $2 " ]] && echo 1 || echo 0
}

while IFS= read -r attr_line
do
  trimmed_attrs=$(echo "$attr_line" | grep -E -o "data-[a-z0-9\-]+")
  while IFS= read -r attr
  do
    if [[ $(contains "$exceptions" "$attr") -eq "0" ]]; then
      attr_file=$(echo "$attr_line" | cut -d ":" -f 1)
      attr_file=${attr_file#"./"}
      attr_line_number=$(echo "$attr_line" | cut -d ":" -f 2)
      attr_full_line=$(echo "$attr_line" | cut -d ":" -f 3)
      echo -e "::error file=$attr_file,line=$attr_line_number::Illegal attribute '$attr' in file '$attr_file' at line $attr_line_number.\n$(echo $attr_full_line | xargs)\n"
    fi
  done < <(printf '%b\n' "$trimmed_attrs") 
done < <(printf '%b\n' "$attr_matching")
