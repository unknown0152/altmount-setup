#!/usr/bin/env bash
# Logging helpers. All output goes to stderr so stdout stays clean for data.

log::info()  { printf '\033[36m[info]\033[0m %s\n'  "$*" >&2; }
log::warn()  { printf '\033[33m[warn]\033[0m %s\n'  "$*" >&2; }
log::error() { printf '\033[31m[err ]\033[0m %s\n'  "$*" >&2; }
log::die()   { log::error "$*"; exit 1; }
