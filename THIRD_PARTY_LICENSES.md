# Third-party licenses

The generated binaries contain GPAC and FFmpeg, together with the dependency
set selected by the variant. Their upstream license texts are copied into
each archive by `util/licenses.sh`.

## GPAC

GPAC is available under the GNU Lesser General Public License, version 2.1 or
later. The exact source commit is recorded in `BUILD_INFO.json`.

## FFmpeg

FFmpeg is available under the GNU Lesser General Public License, version 2.1
or later, with optional GPL components. The configured dependency graph is
recorded in `BUILD_INFO.json`; full builds using GPL codec libraries are
labelled GPL-compatible rather than LGPL-only.

## Corresponding source

The source repositories and immutable commits used for an artifact are
recorded in its metadata. The build scripts in this repository provide the
corresponding-source build procedure.

