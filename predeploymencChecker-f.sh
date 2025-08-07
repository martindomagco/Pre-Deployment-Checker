#!/bin/bash

#check if manifest is present
validate_manifes() {
    local manifest="$1"
    if [ ! -f "$manifest" ]; then
        echo "Manifest file $manifest does not exist"
        exit 1
    else
        echo "SCANNING $manifest MANIFEST"
        echo "============================="
    fi
}

#get the service name from basename
get_basename() {
    local path="$1"
    basename "$path"
}

#get version from version.txt or package.json
get_version() {
    local path="$1"
    #get the version
    if [[ -f "$path/version.txt" ]]; then
        cat "$path/version.txt"
    elif 
        [[ -f "$path/package.json" ]]; then
        jq -r '.version // "unknown"' "$path/package.json"
    else
        echo "unknown"
    fi
}

#get artifact status from curl
get_artifacts() {
    local svc_name="$1"
    local version="$2"

    if [[ "$version"=="unknown" ]]; then #skips checking if version is unknown
        echo "n/a"
    else
        local curl_output
        curl_output=$(curl -s "https://api.mockrepo.com/check-aritiafct/$svc_name/$version")
        echo "$curl_output" | jq -r '.status // "error_checking_artifact"'
    fi
}

#check if path is blank/not a directory & get svc, version, artifact per path
read_paths() {
    local path="$1"

    if [[ -z "$path" ]]; then #skips blank/null lines
        return
    fi

    if [[ ! -d "$path" ]]; then
        echo "DIRECTORY NOT FOUND: Service Directory $path"
        echo "--------------------"
        return
    fi

    local svc_name=$(get_basename "$path")
    local version=$(get_version "$path")
    local artifact=$(get_artifacts "$svc_name" "$version")

    echo "Service: $svc_name"
    echo "Version: $version"
    echo "Artifact: $artifact"
    echo "--------------------"
}

#main function
main() {
    local manifest="$1"
    validate_manifes "$manifest"

    while read -r path; do
        read_paths "$path"
    done < "$manifest"

}

main "$1"