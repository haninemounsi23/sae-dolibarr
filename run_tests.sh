#!/usr/bin/env bash
# Lance les tests (necessite bats et php-cli).
cd "$(dirname "$0")" && exec bats tests/
