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

# compile and exercise the standalone TypeScript backend sample
npm install --prefix "$script_dir/typescript-backend" --ignore-scripts --package-lock=false
server_checksum_before=$(shasum "$script_dir/typescript-backend/src/server.ts")
test_checksum_before=$(shasum "$script_dir/typescript-backend/test.mjs")
"$script_dir/cli/.build/release/cli" --backend-only
generated_checksum_before=$(shasum "$script_dir/typescript-backend/src/generated/routes.ts")
"$script_dir/cli/.build/release/cli" --backend-only
server_checksum_after=$(shasum "$script_dir/typescript-backend/src/server.ts")
test_checksum_after=$(shasum "$script_dir/typescript-backend/test.mjs")
generated_checksum_after=$(shasum "$script_dir/typescript-backend/src/generated/routes.ts")
[[ "$server_checksum_before" == "$server_checksum_after" ]]
[[ "$test_checksum_before" == "$test_checksum_after" ]]
[[ "$generated_checksum_before" == "$generated_checksum_after" ]]
npm run --prefix "$script_dir/typescript-backend" build
node "$script_dir/typescript-backend/test.mjs"

# validate OpenAPI YAML and build browsable documentation
redocly lint --extends minimal "$script_dir/openapi/openapi.yaml"
redocly build-docs "$script_dir/openapi/openapi.yaml" --output "$script_dir/openapi/index.html"
