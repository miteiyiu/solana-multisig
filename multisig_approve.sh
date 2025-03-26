#!/bin/bash

# Multisig Transaction Approval Script

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <MULTISIG_ACCOUNT_ADDRESS> <PATH_TO_OWNER_KEYPAIR>"
    exit 1
fi

# Assign arguments to variables
MULTISIG_ACCOUNT=$1
OWNER_KEYPAIR=$2

# Function to list pending transactions
list_pending_transactions() {
    echo "Listing pending transactions for multisig account: $MULTISIG_ACCOUNT"
    solana multisig list-transactions --multisig-account $MULTISIG_ACCOUNT
}

# Function to approve a specific transaction
approve_transaction() {
    local TRANSACTION_ID=$1
    echo "Approving transaction $TRANSACTION_ID"
    solana multisig approve \
        --multisig-account $MULTISIG_ACCOUNT \
        --keypair $OWNER_KEYPAIR \
        $TRANSACTION_ID
}

# Main script logic
main() {
    # List pending transactions
    list_pending_transactions

    # Prompt user to select a transaction to approve
    echo -n "Enter the Transaction ID to approve (or 'q' to quit): "
    read TRANSACTION_ID

    # Check if user wants to quit
    if [ "$TRANSACTION_ID" = "q" ]; then
        echo "Exiting script."
        exit 0
    fi

    # Approve the selected transaction
    approve_transaction $TRANSACTION_ID

    # Check approval status
    if [ $? -eq 0 ]; then
        echo "Transaction $TRANSACTION_ID approved successfully."
    else
        echo "Failed to approve transaction $TRANSACTION_ID"
    fi
}

# Run the main function
main
