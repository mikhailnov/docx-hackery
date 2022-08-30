#!/usr/bin/env bash
# Unzip docx into specified directory
# and format its xml

set -x
set -e
set -u

file="$1"
dir="$2"

rm -fvr "$dir"
mkdir -p "$dir"
unzip -d "$dir" "$file"
cat "$dir"/word/document.xml | xmllint --format - > "$dir"/word/document2.xml
mv "$dir"/word/document2.xml "$dir"/word/document.xml
