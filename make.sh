#!/bin/bash

set -e
shopt -s extglob

if [[ $# == 0 ]]; then
    ios=false
else
    ios=$1
    shift
fi

if "${ios}"; then

out=ios
sudo xcode-select --switch /Applications/Xcode.app
flags=(cycc -- -miphoneos-version-min=2.0 -arch armv6)

else

out=out
sudo xcode-select --switch /Applications/Xcode.app

if which xcrun &>/dev/null; then
    flags=(xcrun -sdk macosx g++)
    flags+=(-mmacosx-version-min=10.4)
    flags+=(-arch "$(uname -m)")
else
    flags=(g++)
fi

fi

sdk=$(xcodebuild -sdk iphoneos -version Path)

flags+=(-I.)
flags+=(-I"${sdk}"/usr/include/libxml2)
flags+=(-Ilibplist/include)
flags+=(-Ilibplist/libcnary/include)
flags+=(-I/usr/local/opt/openssl/include)

flags+=("$@")

mkdir -p "${out}"
os=()

for c in libplist/libcnary/!(cnary).c libplist/src/*.c; do
    o=${c%.c}.o
    o="${out}"/${o##*/}
    os+=("${o}")
    if [[ "${c}" -nt "${o}" ]]; then
        "${flags[@]}" -c -o "${o}" -x c "${c}"
    fi
done

set -x

"${flags[@]}" -c -std=c++11 -o "${out}"/ldid.o ldid.cpp
"${flags[@]}" -o "${out}"/ldid "${out}"/ldid.o "${os[@]}" -x c lookup2.c -lxml2 -framework Security -lcrypto

if ! "${ios}"; then
    ln -sf out/ldid .
fi