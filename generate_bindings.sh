#!/bin/bash

# Clean and build
forge clean && forge build

# Create abis directory
mkdir -p abis

# Find all Solidity files directly in src directory (not in subdirectories)
sol_files=$(find src -maxdepth 1 -name "*.sol")

for sol_file in $sol_files; do
  # Extract contract name from filename (without path and extension)
  filename=$(basename "$sol_file")
  contract_name="${filename%.sol}"
  
  # Check if the JSON output exists
  json_file="out/$contract_name.sol/$contract_name.json"
  if [ ! -f "$json_file" ]; then
    echo "Warning: $json_file not found, skipping $contract_name"
    continue
  fi
  
  echo "Processing $contract_name..."
  
  # Extract ABI
  jq .abi "$json_file" > "abis/$contract_name.abi.json"
  
  # Create bindings directory and generate Go bindings
  mkdir -p "bindings/$contract_name"
  
  # Convert contract name to lowercase for package name (Go convention)
  package_name=$(echo "$contract_name" | tr '[:upper:]' '[:lower:]')
  
  abigen --abi "abis/$contract_name.abi.json" --pkg "$package_name" --type "$contract_name" --out "bindings/$contract_name/$contract_name.go"
  
  echo "Generated bindings for $contract_name"
done

echo "All bindings generated successfully!"