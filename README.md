# remilioERC721

remilioERC721 is a small implementation of the ERC721 standard, created as part of a learning exercise on Ethereum Improvement Proposals (EIPs). This smart contract allows for the creation, management, and transfer of non-fungible tokens (NFTs) with additional functionality for blacklisting tokens.

## Features

- **ERC721 Compliance**: Implements the ERC721 standard for NFTs.
- **Blacklist Functionality**: Allows the admin to blacklist and unblacklist tokens.
- **Ownership Management**: Tracks ownership and transfer of tokens.
- **Token Metadata**: Supports setting base URI for token metadata.
- **Approval Mechanisms**: Allows for individual and operator approvals for token transfers.

## Prerequisites

- Solidity ^0.8.19
- OpenZeppelin Contracts (for Strings library)

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/your-repo/remilioERC721.git
    cd remilioERC721
    ```

2. Install dependencies (if any):
    ```sh
    npm install
    ```

3. Compile the smart contract using your preferred Solidity compiler.

## Contract Overview

### remilioERC721

This contract implements the ERC721 interface along with additional features for blacklisting tokens. The following sections detail the functions and their purposes.

### Contributing
Contributions are welcome! Feel free to open an issue or submit a pull request.

```sh
       _                            _ _   
__   _| | __ _ ___    _   _ ___  __| | |_ 
\ \ / / |/ _` / __|  | | | / __|/ _` | __|
 \ V /| | (_| \__ \  | |_| \__ \ (_| | |_ 
  \_/ |_|\__,_|___/___\__,_|___/\__,_|\__|
                 |_____|                  
```
