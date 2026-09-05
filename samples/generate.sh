#!/bin/zsh
set -euo pipefail

script_dir="${0:A:h}"

# build the cli, then generate the api
swift build --package-path "$script_dir/cli" -c release
cd "$script_dir"
"$script_dir/cli/.build/release/cli"

# compile generated TypeScript sample
npm install --prefix "$script_dir/typescript" --ignore-scripts --package-lock=false
npm run --prefix "$script_dir/typescript" build

# validate OpenAPI YAML and build browsable documentation
redocly lint --extends minimal "$script_dir/openapi/openapi.yaml"
redocly build-docs "$script_dir/openapi/openapi.yaml" --output "$script_dir/openapi/index.html"
