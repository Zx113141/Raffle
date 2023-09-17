const {ethers} = require('hardhat')

const networkConfig = {
    11155111:{
        name:'sepolia',
        vrfCoordinatorV2: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
        entranceFee:ethers.utils.parseEther('0.01'),
        gasLane:'0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c',
        subscriptionId:'0',
        updateInterval:'30',
        callbackGasLimit:'500000'
    },
    31337:{
        name: "localhost",
        subscriptionId: "588",
        updateInterval: "30",
        raffleEntranceFee: ethers.utils.parseEther("0.01"), // 0.01 ETH
        callbackGasLimit: "500000", // 500,000 gas
        gasLane:'0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c',

    }
}

const developmentChains = ['hardhat', 'localhost']

module.exports = {
    networkConfig,
    developmentChains
}