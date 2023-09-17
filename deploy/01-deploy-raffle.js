const { network, ethers } =require('hardhat')
const { networkConfig, developmentChains } = require('../helper-hardhat-config')
const {verify} = require('../utils/verify')
const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther('30')

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId
    let vrfCoordinatorV2Address, subscribeId
    if (developmentChains.includes(network.name)) {
        const vrfCoordinatorV2Mock = await ethers.getContract('VRFCoordinatorV2Mock')
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address

        // waiting for tx， create subscribeId
        const transactionResponse = await vrfCoordinatorV2Mock.createSubscription()
        const transactionReceipt = await transactionResponse.wait(1)
        subscribeId = transactionReceipt.events[0].args.subId
 
        //  fund the subscription 
        await vrfCoordinatorV2Mock.fundSubscription(subscribeId, VRF_SUB_FUND_AMOUNT)
      
    }else {
        vrfCoordinatorV2Address = networkConfig[chainId]['vrfCoordinatorV2']
    }

    const entranceFee = networkConfig[chainId]['entranceFee']
    const gasLane = networkConfig[chainId]['gasLane']
    const subscriptionId = networkConfig[chainId]['subscriptionId']
    const callbackGasLimit = networkConfig[chainId]['callbackGasLimit']
    const updateInterval = networkConfig[chainId]['updateInterval']
    const args = [vrfCoordinatorV2Address, entranceFee, gasLane, subscriptionId, callbackGasLimit, updateInterval]
    
    const raffle = await deploy("Raffle", {
        from:deployer,
        args,
        log:true,
        waitConfirmations:network.config.blockConfirmations || 1
    })

    // if (!developmentChains.includes(network.name) && process.env.ETH) {
    //     await verify(raffle.address, args)
    // } 
}

module.exports.tags = ['all', 'raffle']