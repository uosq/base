#!/usr/bin/env bash
set -euo pipefail

luabundler bundle "init.lua" -p "$PWD/?.lua" -o "build/base.lua"