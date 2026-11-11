#  bash-json-parser

## WTF
Pure bash JSON parser
Requires Bash 4.3+. Input - valid json.

## Example

```bash
source ./json.sh

declare -A document
json_parse document "$(< package.json)"

json_get document 'scripts.build'

json_get document 'engines.node' node_version
printf 'Node: %s\n' "$node_version"

json_parse document '{"x":{"y":[{"z":"value"}]}}'
json_get document 'x.y.0.z' result
printf '%s\n' "$result"
```

## Testing

```bash
bash test.sh
```
