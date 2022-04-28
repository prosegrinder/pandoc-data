#!/usr/bin/env bash

# Convert a Markdown file to .docx
# Rule 1: Use Pandoc only where necessary

# Figure out where everything is
SCRIPT="$(realpath "$0")"
SCRIPT_PATH="$(dirname "$SCRIPT")"
FILTERS_PATH="$(realpath "$SCRIPT_PATH/..")"
export LUA_PATH
LUA_PATH="$FILTERS_PATH/?.lua;;"
PANDOC_TEMPLATES="$(dirname "$SCRIPT_PATH")"
SHUNN_LONG_STORY_DIR="$PANDOC_TEMPLATES/shunn/long"

# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash/
FILES=()
while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
    -h|--help)
    echo "
md2long.sh --output DOCX [--overwrite] [--modern] FILES

  -o DOCX               --output=DOCX
    Write the output to DOCX. Passed straight to pandoc as-is.
  -x                    --overwrite
    If output FILE exists, overwrite without prompting.
  -m                    --modern
    Use Shunn modern manuscript format (otherwise use Shunn classic)
  FILES
    One (1) or more Markdown file(s) to be converted to DOCX.
    Passed straight to pandoc as-is.

"
    exit 0
    ;;
    -x|--overwrite)
    OVERWRITE="1"
    shift
    ;;
    -m|--modern)
    MODERN="1"
    shift
    ;;
    -o|--output) # output file
    OUTFILE="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # files to process
    FILES+=("$1")
    shift # past argument
    ;;
  esac
done

if [[ -z "$OUTFILE" ]]; then
  echo "No --output argument given."
  exit 1
else
  OUTFILE="$(realpath "$OUTFILE")"
fi

# Prompt for confirmation if ${OUTFILE} exists.
if [[ -f "$OUTFILE" && -z "$OVERWRITE" ]]; then
  echo "$OUTFILE exists."
  echo "Do you want to overwrite it?"
  select yn in "Yes" "No"; do
      case $yn in
          Yes ) echo "Overwriting."; break;;
          No ) echo "Cancelling."; exit;;
      esac
  done
fi

if [[ -n "$MODERN" ]]; then
    TEMPLATE='template-modern.docx'
else
    TEMPLATE='template.docx'
fi

# Create a temporary data directory
echo "Creating temporary directory."
export PANDOC_DATA_DIR
PANDOC_DATA_DIR="$(mktemp -d)"
echo "Directory created: $PANDOC_DATA_DIR"

# Prep the template and reference directories
echo "Extracting $SHUNN_LONG_STORY_DIR/$TEMPLATE to temporary directory."
unzip -ao "$SHUNN_LONG_STORY_DIR/$TEMPLATE" -d "$PANDOC_DATA_DIR/template" > /dev/null
unzip -ao "$SHUNN_LONG_STORY_DIR/$TEMPLATE" -d "$PANDOC_DATA_DIR/reference" > /dev/null
echo "Files extracted."

# Run pandoc
echo "Running Pandoc."
pandoc \
  --from=markdown \
  --to=docx \
  --lua-filter="$SHUNN_LONG_STORY_DIR/shunnlong.lua" \
  --data-dir="$PANDOC_DATA_DIR" \
  --output="$OUTFILE" \
  "${FILES[@]:0}"
echo "Pandoc completed successfully."

# Clean up the temporary directory
echo "Removing $PANDOC_DATA_DIR"
rm -rf "$PANDOC_DATA_DIR"
echo "Done."
