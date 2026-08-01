#!/usr/bin/env -S just --justfile

set lazy
set quiet
set script-interpreter := ['sh', '-eu']
set shell := ['bash', '-euo', 'pipefail', '-c']

[group: 'bootstrap']
mod bootstrap "bootstrap"

# [group: 'k8s']
# mod k8s "kubernetes"

[group: 'talos']
mod talos "talos"

[private]
[script]
default:
    just -l

[private]
[script]
log lvl msg *args:
    gum log -t rfc3339 -s -l "{{ lvl }}" "{{ msg }}" {{ args }}

[private]
[script]
template file *args:
    minijinja-cli "{{ file }}" {{ args }}

[private]
[script]
template-with-data file data *args:
    minijinja-cli --strict {{ args }} "{{ file }}" "{{ data }}"