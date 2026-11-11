#!/usr/bin/env bash
set -euo pipefail
test_file=${BASH_SOURCE[0]}
[[ $test_file == */* ]] || test_file=./$test_file
cd -- "${test_file%/*}"
source ./json.sh

declare -A document
check() {
    local actual
    json_get document "$1" actual
    if [[ $actual != "$2" ]]; then
        printf 'FAIL %s: expected <%s>, got <%s>\n' "$1" "$2" "$actual" >&2
        exit 1
    fi
}

json_parse document "$(< package.json)"
check name wf
check private true
check scripts.build 'turbo run build'
check engines.node 26.13.0
check devDependencies.turbo '^2'

json_parse document '{"x":{"y":[{"z":"hello"},null,false,-1.20e+03,"",[],{}]},"esc":"a\n\u0041\"\\z","a:b":{"c":"ok"},"":"empty key"}'
check x.y.0.z hello
check x.y.1 ''
check x.y.2 false
check x.y.3 '-1.20e+03'
check x.y.4 ''
check x.y.5 '[]'
check x.y.6 '{}'
check esc 'a\n\u0041\"\\z'
check a:b.c ok
if json_get document x.y.99; then
    printf 'FAIL: missing path succeeded\n' >&2
    exit 1
fi
json_parse document 'null'
check '' ''
if json_get document x; then exit 1; fi
json_parse document '"root\n"'
check '' 'root\n'
json_parse document '[true,[1,2],{"z":null}]'
check 0 true
check 1.1 2
check 2.z ''
check 1 '[1,2]'
printf 'All tests passed\n'
