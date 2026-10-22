#!/bin/bash

source .jdk-versions.sh

download_jre() {
    local prefix="$1"
    local archive="$2"
    local output="$3"
    local release_var="${prefix}_RELEASE"
    local checksum_var="${prefix}_CHKSUM"
    local link_var="${prefix}_LINK"
    local release="${!release_var}"
    local checksum="${!checksum_var}"
    local link="${!link_var}"

    if ! [ -f "$archive" ] ; then
        curl -Lo "$archive" "$link"
    fi

    if [ "$(uname -s)" = Darwin ] ; then
        echo "$checksum  $archive" | shasum -c
    else
        echo "$checksum  $archive" | sha256sum -c
    fi

    if ! [ -d "$output" ] ; then
        case "$archive" in
            *.zip)
                local temp_dir
                temp_dir=$(mktemp -d)
                unzip -o "$archive" -d "$temp_dir"
                mv "$temp_dir/$release-jre" "$output"
                rmdir "$temp_dir"
                ;;
            *.tar.gz)
                local strip=1
                local root="$release-jre"
                case "$prefix" in
                    MAC_*) strip=3; root="$root/Contents/Home" ;;
                esac
                mkdir -p "$output"
                tar zxf "$archive" -C "$output" --strip-components="$strip" "$root"
                ;;
        esac
    fi
}
