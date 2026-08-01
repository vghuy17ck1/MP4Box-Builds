#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/full.sh"

variant_setup() {
    full_variant_setup
    export VARIANT=shared-full BASE_VARIANT=full LINKAGE=shared EFFECTIVE_LICENSE=GPL-2.1-or-later
}
