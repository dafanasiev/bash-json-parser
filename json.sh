# Pure Bash JSON reader (Bash 4.3+). Input must be valid JSON.
# Public variable names must not start with __bj_.

__bj_space() {
    while [[ ${__bj_source:__bj_pos:1} == [$' \t\r\n'] ]]; do
        ((__bj_pos += 1))
    done
}

# Keep everything between quotes verbatim, including backslash escapes.
__bj_string() {
    local __bj_start
    ((__bj_pos += 1))
    __bj_start=$__bj_pos
    while [[ ${__bj_source:__bj_pos:1} != '"' ]]; do
        if [[ ${__bj_source:__bj_pos:1} == \\ ]]; then
            ((__bj_pos += 1))
        fi
        ((__bj_pos += 1))
    done
    __bj_text=${__bj_source:__bj_start:__bj_pos-__bj_start}
    ((__bj_pos += 1))
}

__bj_value() {
    local __bj_id=$1 __bj_start __bj_kind __bj_close
    local __bj_key __bj_child __bj_index=0
    __bj_space
    __bj_start=$__bj_pos
    case ${__bj_source:__bj_pos:1} in
        '"')
            __bj_string
            __bj_tree[v:$__bj_id]=$__bj_text
            ;;
        '{'|'[')
            __bj_kind=${__bj_source:__bj_pos:1}
            if [[ $__bj_kind == '{' ]]; then __bj_close='}'; else __bj_close=']'; fi
            ((__bj_pos += 1))
            __bj_space
            while [[ ${__bj_source:__bj_pos:1} != "$__bj_close" ]]; do
                if [[ $__bj_kind == '{' ]]; then
                    __bj_string
                    __bj_key=$__bj_text
                    __bj_space
                    ((__bj_pos += 1)) # colon
                else
                    __bj_key=$__bj_index
                    ((__bj_index += 1))
                fi
                ((__bj_next += 1))
                __bj_child=$__bj_next
                __bj_tree[e:$__bj_id:$__bj_key]=$__bj_child
                __bj_value "$__bj_child"
                __bj_space
                if [[ ${__bj_source:__bj_pos:1} == ',' ]]; then
                    ((__bj_pos += 1))
                    __bj_space
                fi
            done
            ((__bj_pos += 1))
            __bj_tree[v:$__bj_id]=${__bj_source:__bj_start:__bj_pos-__bj_start}
            ;;
        *)
            while [[ -n ${__bj_source:__bj_pos:1} && ${__bj_source:__bj_pos:1} != [$' \t\r\n,]}'] ]]; do
                ((__bj_pos += 1))
            done
            __bj_text=${__bj_source:__bj_start:__bj_pos-__bj_start}
            [[ $__bj_text != null ]] || __bj_text=''
            __bj_tree[v:$__bj_id]=$__bj_text
            ;;
    esac
    return 0
}

# Usage: declare -A document; json_parse document "$json"
json_parse() {
    [[ $# == 2 && $1 =~ ^[a-zA-Z_][a-zA-Z_0-9]*$ && $1 != __bj_* ]] || return 2
    local -n __bj_tree=$1
    local __bj_source=$2 __bj_pos=0 __bj_next=0 __bj_text=''
    __bj_tree=()
    __bj_value 0
}

# Usage: json_get document 'scripts.build' [output_variable]
# Empty path selects the root. Missing path returns 1; bad arguments return 2.
json_get() {
    [[ $# == 2 || $# == 3 ]] || return 2
    [[ $1 =~ ^[a-zA-Z_][a-zA-Z_0-9]*$ && $1 != __bj_* ]] || return 2
    if [[ $# == 3 ]]; then
        [[ $3 =~ ^[a-zA-Z_][a-zA-Z_0-9]*$ && $3 != __bj_* ]] || return 2
    fi
    local -n __bj_tree=$1
    local __bj_path=$2 __bj_id=0 __bj_key __bj_edge
    if [[ -n $__bj_path ]]; then
        while :; do
            __bj_key=${__bj_path%%.*}
            __bj_edge=e:$__bj_id:$__bj_key
            [[ -v __bj_tree[$__bj_edge] ]] || return 1
            __bj_id=${__bj_tree[$__bj_edge]}
            [[ $__bj_path == *.* ]] || break
            __bj_path=${__bj_path#*.}
        done
    fi
    [[ -v __bj_tree[v:$__bj_id] ]] || return 1
    if [[ $# == 3 ]]; then
        printf -v "$3" '%s' "${__bj_tree[v:$__bj_id]}"
    else
        printf '%s' "${__bj_tree[v:$__bj_id]}"
    fi
}
