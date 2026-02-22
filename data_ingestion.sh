nano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.shnano -c data_ingestion.sh#!/bin/bash
set -euo pipefail

CONTAINER=namenode
HDFS_USER=hadoop

HDFS_DIR="/project/data/linkedin/raw"
HDFS_FILE="job_skills.csv"
TARGET="$HDFS_DIR/$HDFS_FILE"

INPUT="${1:?usage: $0 /path/to/file.csv|zip}"

echo "uploading $(date)"
echo "file input: $INPUT"
echo "file output: $TARGET"

docker exec -u "$HDFS_USER" "$CONTAINER" hdfs dfs -mkdir -p "$HDFS_DIR"

if [[ "$INPUT" == *.zip ]]; then
  command -v unzip >/dev/null || { echo "[error] not unzipped"; exit 2; }
  echo "get csv from zip"
  CSV_ENTRY="$(unzip -Z1 "$INPUT" | grep -i '\.csv$' | head -n 1)"
  [[ -n "$CSV_ENTRY" ]] || { echo "[error] no csv found in zip"; exit 3; }
  unzip -p "$INPUT" "$CSV_ENTRY" | \
    docker exec -i -u "$HDFS_USER" "$CONTAINER" hdfs dfs -put -f - "$TARGET"
else
  echo "[info] uploading csv..."
  docker exec -i -u "$HDFS_USER" "$CONTAINER" hdfs dfs -put -f - "$TARGET" < "$INPUT"
fi

echo "HDFS dir info"
docker exec -u "$HDFS_USER" "$CONTAINER" hdfs dfs -ls "$HDFS_DIR"

echo "[check] size:"
docker exec -u "$HDFS_USER" "$CONTAINER" hdfs dfs -du -h "$TARGET"

echo "quick peek:"
docker exec -u "$HDFS_USER" "$CONTAINER" bash -lc "hdfs dfs -cat '$TARGET' 2>/dev/null | head -n 5" | sed 's/^/  /'
echo "done."


