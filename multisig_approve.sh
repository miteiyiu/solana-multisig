#!/bin/bash

# Configuration - Adjust paths to match your setup
KEYS=("owner1.json" "owner2.json")  # Key files for owners
TX_FILE="pending_tx.json"  # File containing the transaction to approve
OUTPUT_TX="signed_tx.json"  # Output file for the fully signed transaction
FEE_PAYER="${KEYS[0]}"  # First owner will pay transaction fees
MULTISIG_ADDRESS="4P8GVC6XEo2ro96BdocZxfFtg5Mu5woXwMWo2vThykcn"  # Fill in your multisig address here or pass as an argument

# Parse command line arguments
KEY_TO_USE=""
SUBMIT=false

function print_usage {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --key KEYFILE                   Specify key file to sign with (required)"
  echo "  --tx-file FILENAME              Transaction file to sign (default: pending_tx.json)"
  echo "  --output FILENAME               Output file for signed transaction (default: signed_tx.json)"
  echo "  --submit                        Submit transaction after signing"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)
      KEY_TO_USE="$2"
      shift 2
      ;;
    --tx-file)
      TX_FILE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_TX="$2"
      shift 2
      ;;
    --submit)
      SUBMIT=true
      shift
      ;;
    *)
      print_usage
      ;;
  esac
done

# Validate required parameters
if [ -z "$KEY_TO_USE" ]; then
  echo "Error: Key file is required. Use --key option."
  print_usage
fi

# Check if key file exists
if [ ! -f "$KEY_TO_USE" ]; then
  echo "Error: Key file '$KEY_TO_USE' not found."
  exit 1
fi

# Check if transaction file exists
if [ ! -f "$TX_FILE" ]; then
  echo "Error: Transaction file '$TX_FILE' not found."
  exit 1
fi

# Check required Solana CLI tools
if ! command -v solana &> /dev/null; then
  echo "Error: Solana CLI not found. Please install it first."
  exit 1
fi

# Get the public key from the key file
SIGNER_PUBKEY=$(solana-keygen pubkey "$KEY_TO_USE")
echo "Signing with key: $SIGNER_PUBKEY from file: $KEY_TO_USE"

# Get the latest blockhash
BLOCKHASH=$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash"}' https://api.mainnet-beta.solana.com | jq -r '.result.value.blockhash')
if [ -z "$BLOCKHASH" ]; then
  echo "Error: Failed to get blockhash"
  exit 1
fi
echo "Using blockhash: $BLOCKHASH"

# Sign the transaction
echo "Signing transaction from $TX_FILE..."

# Check if the output file already exists (multisig may require multiple signatures)
if [ -f "$OUTPUT_TX" ]; then
  echo "Found existing partially signed transaction in $OUTPUT_TX"
  # Sign existing transaction
  solana sign \
    --signer "$KEY_TO_USE" \
    --blockhash "$BLOCKHASH" \
    -t "$OUTPUT_TX" \
    "$TX_FILE" || {
      echo "Error: Failed to sign existing transaction"
      exit 1
    }
else
  # Create new signed transaction
  solana sign \
    --signer "$KEY_TO_USE" \
    --blockhash "$BLOCKHASH" \
    -o "$OUTPUT_TX" \
    "$TX_FILE" || {
      echo "Error: Failed to sign transaction"
      exit 1
    }
fi

echo "Transaction signed and saved to $OUTPUT_TX"

# Submit if requested and transaction is complete
if [ "$SUBMIT" = true ]; then
  echo "Submitting transaction to the Solana network..."
  
  # Submit transaction
  solana send "$OUTPUT_TX" || {
      echo "Error: Failed to submit transaction"
      exit 1
    }
  
  echo "Transaction submitted successfully!"
else
  echo "Transaction not submitted. Add --submit flag to submit after signing."
  echo "Note: For multisig, all required signers must sign before submission."
fi
