#!/usr/bin/env bash
# Convert one line table into just text
# (a table which consists of one row makes no sense
# and break automatic enumeration of real tables)

set -x
set -e
set -u

# $1: file
file="$1"
# $2: text inside table
text="$2"
test -f "$file"
grep -q "$2" "$file"

# Example line:
# <w:t># setfacl -x u:user1 file1</w:t>
# Delete all lines from <w:tbl> up to </w:tbl>
# inside which this lines ($2) is

# Number of line where $text is
n1="$(grep -nE "<w:t>.*${text}" "$file" | head -n1 | awk -F ':' '{print $1}')"
c=0
while read -r line
do
	if [[ "$line" =~ "<w:tbl>" ]]; then
		break
	fi
	c=$((++c))
done <<< "$(head -n "$n1" "$file" | tac)"
! test c = 0
# Number of line where "<w:tbl>" is
n2=$((n1 - c))

c=0
while read -r line
do
	if [[ "$line" =~ "</w:tbl>" ]]; then
		break
	fi
	c=$((++c))
done <<< "$(awk "NR >= ${n1}" "$file")"
# awk: https://unix.stackexchange.com/a/47423
# slow but well readable
! test c = 0

# Number of line where "</w:tbl>" is
n3=$((n1 + c))

# Now we need to delete lines from n2 to n3 and insert new line(s) in position n2
sed -i'' -e "${n2},${n3}d" "$file"

# 164 is a document-specific number of style applied to text
insert="
    <w:p>
      <w:pPr>
        <w:pStyle w:val=\"164\"/>
        <w:bidi w:val=\"0\"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:lang w:val=\"en-GB\"/>
        </w:rPr>
        <w:t>${text}</w:t>
      </w:r>
    </w:p>
"

# insert $insert between lines n2 and n3
cat <(awk "NR <= ${n2}" "$file") <(echo "$insert") <(awk "NR >= ${n3}" "$file") > "$file".new
mv "$file" "$file".orig
diff -u --color "$file".orig "$file".new || :
mv "$file".new "$file" 
