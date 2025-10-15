#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <text-to-copy>"
  exit 1
fi

if command -v wl-copy &> /dev/null; then
  wl-copy "$1"
elif command -v xclip &> /dev/null; then
  echo -n "$1" | xclip -selection clipboard
else
  echo "Error: No clipboard tool (wl-copy or xclip) found."
  exit 1
fi
