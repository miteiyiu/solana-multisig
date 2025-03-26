#!/bin/bash

# Multisig Transaction Initiation Script

# Function to display usage instructions
usage() {
    echo "Usage: $0 <MULTISIG_ACCOUNT> <RECIPIENT_ADDRESS> <AMOUNT_IN_SOL> <PATH_TO_SENDER_KEYPAIR>"
    echo "Example: $0 myaddr recipient_address 1.5 ~/owner1.json"
    exit 1
}

# Check if all required arguments are provided
if [ $# -ne 4 ]; then
    usage
fi

# Assign arguments to variables
MULTISIG_ACCOUNT=$1
RECIPIENT_ADDRESS=$2
AMOUNT=$3
SENDER_KEYPAIR=$4

# Validate inputs
validate_inputs() {
    # Check if keypair file exists
    if [ ! -f "$SENDER_KEYPAIR" ]; then
        echo "Error: Keypair file $SENDER_KEYPAIR does not exist."
        exit 1
    }

    # Validate Solana address format (basic check)
    if [[ ! "$MULTISIG_ACCOUNT" =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]]; then
        echo "Error: Invalid multisig account address."
        exit 1
    }

    # Validate recipient address
    if [[ ! "$RECIPIENT_ADDRESS" =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]]; then
        echo "Error: Invalid recipient address."
        exit 1
    }

    # Validate amount (must be a positive number)
    if [[ ! "$AMOUNT" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Error: Invalid amount. Must be a positive number."
        exit 1
    fi
}

# Create multisig transaction
create_multisig_transaction() {
    echo "Creating multisig transaction..."
    
    # Initiate the transaction
    TRANSACTION_ID=$(solana multisig create-transaction \
        --multisig-account "$MULTISIG_ACCOUNT" \
        --destination "$RECIPIENT_ADDRESS" \
        --amount "$AMOUNT" \
        --keypair "$SENDER_KEYPAIR")

    # Check if transaction creation was successful
    if [ $? -eq 0 ]; then
        echo "Transaction initiated successfully!"
        echo "Transaction ID: $TRANSACTION_ID"
    else
        echo "Failed to create transaction."
        exit 1
    fi
}

# Verify network
check_network() {
    CURRENT_NETWORK=$(solana config get | grep "RPC URL" | awk '{print $3}')
    echo "Current Solana Network: $CURRENT_NETWORK"
    
    read -p "Do you want to continue with this network? (y/n): " CONFIRM
    if [[ "$CONFIRM" != "y" ]]; then
        echo "Please set the correct network using 'solana config set --url <network_url>'"
        exit 1
    fi
}

# Main script execution
main() {
    # Validate inputs first
    validate_inputs

    # Check current network
    check_network

    # Show transaction details for confirmation
    echo -e "\nTransaction Details:"
    echo "Multisig Account: $MULTISIG_ACCOUNT"
    echo "Recipient Address: $RECIPIENT_ADDRESS"
    echo "Amount: $AMOUNT SOL"
    echo "Sender Keypair: $SENDER_KEYPAIR"

    # Prompt for final confirmation
    read -p "Confirm transaction? (y/n): " FINAL_CONFIRM
    if [[ "$FINAL_CONFIRM" == "y" ]]; then
        create_multisig_transaction
    else
        echo "Transaction cancelled."
        exit 0
    fi
}

# Run the main function
main
