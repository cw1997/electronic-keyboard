#!/bin/bash
set -euo pipefail

# Build the design using librelane

if [[ "${CI:-}" == "true" ]]; then
  python3 -m librelane --dockerized ./config.json
else
  librelane ./config.json
fi
