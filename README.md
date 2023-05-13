# securetoken
This repository consists of solution for secure token platform

A smart contract in solidity is developed addressing the implementation mentioned in this document - https://grateful-innovation-6e8.notion.site/Design-and-Develop-a-Secure-Token-Platform-with-Advanced-Features-1119ea6d0576492d9793d5d13fd8a569

Please note that Swap tokens is developed in a basic model without any liquidity pools but assuming that the contract holds tokens from swappable ERC20 tokens and got allowance to transfer.

Also, please note that swap rate is being calculated not in a realistic dex platforms but manually setting the swap rate.

Upgradeability is being achieved using openzeppelin upgradeable contracts.

All functionalities has been tested properly.
