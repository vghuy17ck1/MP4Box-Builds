#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/minimal.sh"

variant_setup() {
    minimal_variant_setup
    export VARIANT=shared-minimal BASE_VARIANT=minimal LINKAGE=shared EFFECTIVE_LICENSE=LGPL-2.1-or-later
}
