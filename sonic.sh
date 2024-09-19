#!/bin/bash

function echo_blue_bold {
    echo -e "\033[1;34m$1\033[0m"
}
echo

# Check if privatekeys.txt exists
if [ ! -f privatekeys.txt ]; then
  echo_blue_bold "Error: privatekeys.txt file not found!"
  exit 1
fi

# Check if npm and @solana/web3.js are installed
if ! npm list @solana/web3.js >/dev/null 2>&1; then
  echo_blue_bold "Installing @solana/web3.js..."
  npm install @solana/web3.js
  echo
else
  echo_blue_bold "@solana/web3.js is already installed."
fi
echo

# Create a temporary Node.js script
temp_node_file=$(mktemp /tmp/node_script.XXXXXX.js)

cat << EOF > $temp_node_file
const fs = require("fs");
const { Connection, Keypair, SystemProgram, Transaction, sendAndConfirmTransaction } = require("@solana/web3.js");

// Load private keys from file
const privateKeys = fs.readFileSync("privatekeys.txt", "utf8").trim().split("\\n");

// Define Solana testnet URL and other constants
const connection = new Connection("https://api.testnet.solana.com", "confirmed");
const programId = "YourProgramIDHere"; // Replace with your program ID
const transactionData = Buffer.from("YourTransactionDataHere", "hex");
const numberOfTransactions = 1;

async function sendTransaction(wallet) {
    const tx = new Transaction().add(
        SystemProgram.transfer({
            fromPubkey: wallet.publicKey,
            toPubkey: programId,
            lamports: 0, // Specify the amount of SOL to send
        })
    );

    tx.add({
        keys: [{pubkey: wallet.publicKey, isSigner: true, isWritable: true}],
        programId: programId,
        data: transactionData,
    });

    try {
        const signature = await sendAndConfirmTransaction(connection, tx, [wallet]);
        console.log("\\033[1;35mTx Signature:\\033[0m", signature);
    } catch (error) {
        console.error("Error sending transaction:", error);
    }
}

async function main() {
    for (const key of privateKeys) {
        const wallet = Keypair.fromSecretKey(new Uint8Array(JSON.parse(key)));
        for (let i = 0; i < numberOfTransactions; i++) {
            console.log("Checking in from wallet:", wallet.publicKey.toBase58());
            await sendTransaction(wallet);
        }
    }
}

main().catch(console.error);
EOF

# Execute the Node.js script
NODE_PATH=$(npm root -g):$(pwd)/node_modules node $temp_node_file

# Clean up the temporary file
rm $temp_node_file
echo
echo_blue_bold "Follow @CryptChurch on X for more guides like this"
echo
