#!/bin/bash

# Configuration - Adjust paths to match your setup
KEYS=("owner1.json" "owner2.json")
MULTISIG_ADDRESS="4P8GVC6XEo2ro96BdocZxfFtg5Mu5woXwMWo2vThykcn"  # Fill in your multisig address here or pass as an argument
FEE_PAYER="${KEYS[0]}"  # First owner will pay transaction fees
TX_FILE="pending_tx.json"  # File to store the transaction for later approval

# Parse command line arguments
COMMAND=""
RECIPIENT=""
AMOUNT="0.005"
TOKEN_ACCOUNT=""

function print_usage {
  echo "Usage: $0 [--multisig ADDRESS] [command] [options]"
  echo ""
  echo "Commands:"
  echo "  send-sol RECIPIENT AMOUNT            Send SOL from multisig to recipient"
  echo "  send-token TOKEN_ACCOUNT RECIPIENT AMOUNT   Send tokens from multisig's token account"
  echo ""
  echo "Options:"
  echo "  --multisig ADDRESS                   Specify multisig address (if not in config)"
  echo "  --tx-file FILENAME                   Specify transaction file name (default: pending_tx.json)"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --multisig)
      MULTISIG_ADDRESS="$2"
      shift 2
      ;;
    --tx-file)
      TX_FILE="$2"
      shift 2
      ;;
    send-sol)
      COMMAND="send-sol"
      RECIPIENT="$2"
      AMOUNT="$3"
      shift 3
      ;;
    send-token)
      COMMAND="send-token"
      TOKEN_ACCOUNT="$2"
      RECIPIENT="$3"
      AMOUNT="$4"
      shift 4
      ;;
    *)
      print_usage
      ;;
  esac
done

# Validate required parameters
if [ -z "$MULTISIG_ADDRESS" ]; then
  echo "Error: Multisig address is required. Set it in the script or use --multisig option."
  exit 1
fi

if [ -z "$COMMAND" ]; then
  print_usage
fi

# Check required Solana CLI tools
if ! command -v solana &> /dev/null; then
  echo "Error: Solana CLI not found. Please install it first."
  exit 1
fi

# Function to validate Solana address
validate_address() {
  if ! [[ $1 =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]]; then
    echo "Error: '$1' does not appear to be a valid Solana address."
    exit 1
  fi
}

# Validate addresses
validate_address "$MULTISIG_ADDRESS"
validate_address "$RECIPIENT"

# Get the latest blockhash
BLOCKHASH=$(curl -s -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getLatestBlockhash"}' https://api.mainnet-beta.solana.com | jq -r '.result.value.blockhash')
if [ -z "$BLOCKHASH" ]; then
  echo "Error: Failed to get blockhash"
  exit 1
fi
echo "Using blockhash: $BLOCKHASH"

# Prepare and save transaction based on command
case "$COMMAND" in
  send-sol)
    echo "Initiating SOL transfer: $AMOUNT SOL from multisig to $RECIPIENT"
    
    # Create unsigned transaction
    solana transfer --from "$MULTISIG_ADDRESS" "$RECIPIENT" "$AMOUNT" \
      --fee-payer "$FEE_PAYER" \
      --sign-only \
      --blockhash "$BLOCKHASH" \
      --dump-transaction-message > "$TX_FILE" || {
        echo "Error: Failed to create transaction"
        exit 1
      }
    ;;
    
  send-token)
    echo "Initiating token transfer: $AMOUNT tokens from $TOKEN_ACCOUNT to $RECIPIENT"
    
    # Validate token account
    validate_address "$TOKEN_ACCOUNT"
    
    # Create unsigned token transaction
    spl-token transfer --owner "$MULTISIG_ADDRESS" \
      "$TOKEN_ACCOUNT" "$AMOUNT" "$RECIPIENT" \
      --fee-payer "$FEE_PAYER" \
      --sign-only \
      --blockhash "$BLOCKHASH" \
      --dump-transaction-message > "$TX_FILE" || {
        echo "Error: Failed to create token transaction"
        exit 1
      }
    ;;
    
  *)
    echo "Error: Unknown command '$COMMAND'"
    print_usage
    ;;
esac

echo "Transaction initiated and saved to $TX_FILE"
echo "Use multisig_approve.sh to sign and submit this transaction"
