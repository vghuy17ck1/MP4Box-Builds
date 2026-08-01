#!/usr/bin/env bash
set -euo pipefail

variant_setup() {
    export VARIANT=minimal EFFECTIVE_LICENSE=LGPL-2.1-or-later
    export FFMPEG_LIBRARIES="avformat avcodec avutil swresample swscale"
    export FFMPEG_CONFIGURE_ARGS=(
        --disable-everything
        --disable-programs
        --disable-doc
        --disable-autodetect
        --enable-avformat
        --enable-avcodec
        --enable-avutil
        --enable-swresample
        --enable-swscale
        --enable-protocol=file
        --enable-protocol=pipe
        --enable-protocol=data
        --enable-protocol=tcp
        --enable-protocol=udp
        --enable-demuxer=matroska,webm,mov,mpegts,mpegps,h264,hevc,av1,aac,mp3,flac,ogg,wav
        --enable-muxer=mp4,webm,matroska,mpegts,adts,ogg
        --enable-parser=h264,hevc,av1,vp8,vp9,aac,mpegaudio,flac,opus,vorbis
        --enable-decoder=h264,hevc,av1,vp8,vp9,aac,ac3,eac3,mp3,opus,vorbis,flac,pcm_s16le,pcm_s24le,pcm_s32le
        --enable-bsf=h264_mp4toannexb,hevc_mp4toannexb,aac_adtstoasc,extract_extradata
        --enable-zlib
    )
    export GPAC_CONFIGURE_ARGS=(
        --disable-x11
        --disable-rmtws
        --disable-3d
        --disable-qjs
        --disable-avdevice
        --disable-avfilter
    )
}
