# MP4Box-Builds

MP4Box-Builds builds portable GPAC command-line artifacts containing `MP4Box` and `gpac` for Linux x86-64, Linux ARM64, Windows x86-64, and Windows ARM64.

## Architecture

The build pipeline is:

`util/resolve-refs.sh` -> immutable GPAC and FFmpeg commits -> target toolchain -> static FFmpeg -> static GPAC modules -> binary inspection -> feature detection -> deterministic archive.

The source resolver runs once before a CI matrix. Every matrix job receives the same release and master commits. GPAC master is never paired with a moving FFmpeg branch; FFmpeg defaults to the pinned `FFMPEG_REF` in `versions.env`.

The repository is separated into:

- `targets/`: target architecture, compiler, linker, and runtime settings.
- `variants/`: minimal and full FFmpeg/GPAC feature policies.
- `scripts.d/`: dependency and upstream build stages.
- `channels/`: release and master resolver entry points.
- `util/`: reference resolution, static pkg-config, metadata, licensing, packaging, and prefix validation.
- `tests/`: static, binary-format, runtime, feature, DASH, transcoding, and reproducibility checks.
- `.github/workflows/`: PR, push/manual matrix, stable release, and scheduled development builds.

## Targets

| Target | Architecture | Intended runtime |
|---|---|---|
| `linux64` | x86-64 | static Linux executable |
| `linuxarm64` | AArch64 | static Linux executable |
| `win64` | PE x86-64 | Windows system DLLs only |
| `winarm64` | PE ARM64 | Windows system DLLs only |

Linux builds use static linker flags and reject ELF interpreters and `DT_NEEDED` entries. Windows builds reject GPAC, FFmpeg, OpenSSL, MinGW, libgcc, and libstdc++ runtime imports. `-march=native` and `-mcpu=native` are not used.

## Variants

| Feature | Minimal | Full |
|---|---:|---:|
| MP4Box and gpac | Yes | Yes |
| Static GPAC modules | Yes | Yes |
| FFmpeg libraries | Yes | Yes |
| FFmpeg Matroska/WebM demuxer | Required | Required |
| MKV-to-DASH packaging | Required | Required |
| Essential FFmpeg decoders | Yes | Yes |
| FFmpeg encoders | Limited | Broad policy |
| FFmpeg AVFilter | No | Yes |
| HTTPS and HTTP/2 | Optional | Optional dependency stage |
| QuickJS | No | Yes where supported |
| GUI playback | No | No |
| Effective license | Detected | Detected; often GPL with external GPL codecs |

Both variants keep FFmpeg enabled. Minimal disables desktop-oriented GPAC components but does not use GPAC's unmodified `--static-bin` preset. That preset can disable FFmpeg and other required libraries. The build uses `--static-build --static-modules`, a target prefix, static-only pkg-config resolution, explicit linker flags, and final executable inspection.

The initial full policy uses only redistributable components. External codec libraries are added only when their static target libraries have been built and verified; the effective license is never inferred from the variant name.

TLS verification is disabled at compile time in both variants. FFmpeg ignores its `tls_verify` and `verify` settings before opening a TLS transport. GPAC bypasses certificate validation in its OpenSSL and libcurl download paths. `BUILD_INFO.json` records both source patches. This is intentionally insecure and should only be used with trusted transport networks or separately authenticated content.

## Source channels

| Channel | GPAC reference | Use | Release type |
|---|---|---|---|
| release | GitHub latest published non-draft stable release | production-oriented builds | immutable versioned release |
| master | resolved `refs/heads/master` commit | development and integration testing | rolling prerelease |
| custom | explicit `GPAC_REF` resolved to a commit | testing and bisection | manual only |

Release resolution reads the GitHub release API and then resolves the tag through Git. It does not select the lexically highest tag. Drafts and prereleases are rejected unless `ALLOW_PRERELEASE=1`. Every build records requested ref, resolved ref, full commit, short commit, and version in `BUILD_INFO.json`.

## Local prerequisites

For native Linux work:

- Bash, Git, curl, jq or Python 3, GNU make, C compiler, pkg-config, tar, xz, file, readelf, and a static-capable linker.
- Docker Buildx for reproducible toolchain images.
- FFmpeg source dependencies selected by the variant.

For cross builds, use a maintained AArch64 musl toolchain for Linux and llvm-mingw or an equivalent maintained toolchain for Windows ARM64. The scripts fail when required compiler commands are not found.

## Local commands

Resolve refs:

```bash
SOURCE_CHANNEL=release ./channels/release.sh
SOURCE_CHANNEL=master ./channels/master.sh
```

Build a native minimal release:

```bash
SOURCE_DATE_EPOCH=0 JOBS=4 ./build.sh linux64 minimal release
```

Build the other matrix dimensions:

```bash
./build.sh linux64 full master
./build.sh linuxarm64 minimal release
./build.sh win64 full release
./build.sh winarm64 full master
```

Use overrides without changing repository files:

```GPAC_REF=refs/pull/123/head ./build.sh linux64 minimal release
FFMPEG_REF=n8.1.2 ./build.sh linux64 minimal release
SOURCE_DATE_EPOCH=1700000000 OUTPUT_DIR=artifacts/local ./build.sh linux64 minimal release
```

Build images:

```bash
./makeimage.sh linux64
```

The image definitions are intentionally small; production CI uses pinned action versions and cache keys that include target, variant, source commits, toolchain version, dependency version data, script hash, and patch state.

## Archive contents

Linux archives use:

`mp4box-<gpac-version>-<channel>-<target>-<variant>.tar.xz`

Windows archives use:

`mp4box-<gpac-version>-<channel>-<target>-<variant>.zip`

Master names include `master-<short-commit>`; custom names include a sanitized reference. Every archive contains:

```text
bin/MP4Box or bin/MP4Box.exe
bin/gpac or bin/gpac.exe
README.txt
BUILD_INFO.json
FEATURES.json
THIRD_PARTY_LICENSES.txt
LICENSE-GPAC.txt
LICENSE-FFMPEG.txt
SHA256SUMS
```

The output directory also receives an unpacked `bin/`, `BUILD_INFO.json`, and `FEATURES.json` for CI verification. These are staging conveniences and are not part of the archive's root outside the listed contents.

## Verification

Native smoke tests run:

```bash
MP4Box -version
MP4Box -h
MP4Box -h dash
gpac -version
gpac -h filters
gpac -h ffdmx
gpac -h 'ffdmx:*'
gpac -h ffdec
gpac -h ffbsf
```

The MKV-to-DASH test requires `tests/fixtures/sample.mkv`. Generate the legally redistributable synthetic H.264/AAC fixture with:

```bash
./tests/fixtures/create-sample.sh
./tests/verify-dash-mkv.sh artifacts/local linux64
```

Full native verification adds FFmpeg encoder, AVFilter, video, and audio transcoding checks. Cross targets receive binary-format and static-link verification; runtime claims remain false unless a matching native runner or configured emulator executes them.

Run reproducibility verification:

```SOURCE_DATE_EPOCH=0 ./tests/verify-reproducible.sh linux64 minimal release
```

## GitHub Actions

- `build.yml` resolves both channels once and defines the 4 x 2 x 2 matrix.
- `pr.yml` lints shell/YAML, validates generated metadata, and runs a Linux minimal smoke path.
- `release.yml` publishes immutable release-channel assets with checksums and never publishes master as stable latest.
- `scheduled.yml` runs daily in UTC and publishes master artifacts as development prereleases.
- Manual dispatch filters target, variant, and source channel; `gpac_ref` creates one custom build instead of duplicate release/master builds.
- Fork pull requests receive read-only permissions and no release credentials.
- Failed jobs upload logs and build staging data.

## Metadata and licensing

`BUILD_INFO.json` records source repositories, requested and immutable refs, compiler/toolchain versions, configure arguments, patch state, license, source date epoch, and separate static, format, runtime, DASH, and transcoding statuses.

`FEATURES.json` is generated from final binary help output when execution is available. For cross targets whose architecture cannot execute on the runner, it records `feature_detection: unavailable` rather than claiming that requested flags imply detected features.

The repository build scripts are MIT licensed. GPAC, FFmpeg, and linked dependencies retain their upstream licenses. Full builds may become GPL when GPL libraries are statically linked. No nonfree dependencies are included.

## Known limitations

- Native execution and functional MKV-to-DASH tests are only performed automatically on a matching runner; cross artifacts are inspected without being labelled runtime-tested.
- The fixture generator requires a system FFmpeg for local generation. Supply `MP4BOX_MKV_FIXTURE` for offline or hermetic fixture testing.
- Windows ARM64 requires a maintained llvm-mingw toolchain with `aarch64-w64-mingw32`; a successful configure command alone is not accepted as architecture proof.
- Optional external codec, TLS, HTTP/2, and image dependencies require a static dependency stage before their capabilities can be detected. Missing optional features are recorded in `FEATURES.json`.
- Upstream GPAC and FFmpeg configure interfaces can change. The GPAC stage reads `./configure --help` and fails when required static integration options are unavailable.
- The initial Docker images provide build prerequisites but do not claim to replace a pinned vendor toolchain image. The toolchain name and version are recorded in every artifact.

## Updating sources

Update `versions.env`, run the resolver, build the Linux minimal release first, inspect `config.log` and `BUILD_INFO.json`, then expand to full and cross targets. Keep patches under `patches/gpac/`, `patches/ffmpeg/`, or `patches/dependencies/`; each patch must be narrow, version-guarded, and recorded.
