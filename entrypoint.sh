#!/usr/bin/env bash
set -euo pipefail

AMF_CONTAINER="${AMF_CONTAINER:-oai-amf}"
INTERVAL_SEC="${INTERVAL_SEC:-1}"
OUTPUT_FILE="${OUTPUT_FILE:-/tmp/ngap_imsi_map.log}"

# Ensure output file exists and is empty to start
: > "$OUTPUT_FILE"

# Function to parse the most recent "UEs' Information" table from logs
parse_latest_table() {
  # Pull a bounded slice of recent logs to keep it light but still capture a full table.
  # Adjust --tail if your tables are farther apart.
  docker logs "$AMF_CONTAINER" --tail 500 2>&1 | \
  awk '
    BEGIN{
      start=-1; end=-1;
      dash="\\|[[:space:]]*-+UEs'\'' Information-+[[:space:]]*\\|";
      sep ="\\|[[:space:]]*-+[[:space:]]*\\|";
    }
    {
      lines[NR]=$0;
      if ($0 ~ dash) {
        # remember last table header location
        start=NR;
        end=-1;
      } else if (start>0 && $0 ~ sep) {
        # possible footer lines: keep updating end after header
        end=NR;
      }
    }
    END{
      if (start>0) {
        # If we never found a footer after this header, print until EOF
        if (end < start) end=NR;
        for (i=start; i<=end; i++) print lines[i];
      }
    }'
}

while true; do
  TMP_OUT="$(mktemp)"
  TABLE="$(parse_latest_table || true)"

  if [ -n "$TABLE" ]; then
    echo "$TABLE" | \
    # Split by pipe into fields, trim, and select REGISTERED rows
    awk -F '|' '
      function trim(s){ sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
      BEGIN{ registered_count=0 }
      # Data rows typically have 9 fields (because of leading/trailing pipes). Filter those.
      NF>=9 && $0 ~ /\|/ {
        idx = trim($2);             # Index (unused)
        state = trim($3);           # 5GMM State
        imsi = trim($4);            # IMSI
        guti = trim($5);            # GUTI
        ran  = trim($6);            # RAN UE NGAP ID (e.g., 0x02)
        amf  = trim($7);            # AMF UE NGAP ID (e.g., 0x21)
        plmn = trim($8);            # PLMN
        cell = trim($9);            # Cell Id

        if (state == "5GMM-REGISTERED" && imsi ~ /^[0-9]+$/) {
          print imsi, amf, ran;     # space-separated: IMSI AMF_UE_NGAP_ID RAN_UE_NGAP_ID
          registered_count++
        }
      }
      END{
        # If nothing registered, exit 1 to signal empty file handling
        if (registered_count==0) exit 1
      }' > "$TMP_OUT" || true
  fi

  if [ -s "$TMP_OUT" ]; then
    mv "$TMP_OUT" "$OUTPUT_FILE"
  else
    # Empty or no REGISTERED rows → empty the file
    : > "$OUTPUT_FILE"
    rm -f "$TMP_OUT"
  fi

  sleep "$INTERVAL_SEC"
done
