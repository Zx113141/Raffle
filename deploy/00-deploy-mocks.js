const { networkConfig, developmentChains } = require('../helper-hardhat-config')
const { ethers } = require('hardhat')


const BASE_FEE = ethers.utils.parseEther('0.25');
const GAS_PRICE_LINK = 1e9

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const args = [BASE_FEE, GAS_PRICE_LINK]
    if (developmentChains.includes(network.name)) {
        log('Local network detected! Deploying mocks..')
        await deploy('VRFCoordinatorV2Mock', {
            from: deployer,
            args,
            log: true,

        })
        log('Local deployed!')
    }
}