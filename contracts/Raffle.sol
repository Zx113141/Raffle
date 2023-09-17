// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

// Enter the lottery and pay some amount
// Winner will be selected every X minutes -> completly automated
// Chainlink Oracle -> Randomness, Automated Execution (Chainlink Keeper)
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

enum RaffleState {
    OPEN,
    CLOSE
}

error Raffle_NotEnoughETHEntered();
error Raffle_TransactionFailed();
error Raffle_StatusFailed();
error Raffle_UpkeepNeeded(RaffleState state, uint256 players, uint256 balance);

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
    // Types

    // Storage
    address payable[] private s_players;
    address payable private s_winner;
    RaffleState private s_state = RaffleState.OPEN;
    uint256 private s_lastTimeStamp;
    // Immutable
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private immutable i_interval;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    // Constant
    uint16 private constant REQUEST_COMFIRMATIONS = 3;
    uint32 private constant RANDOM_WORDS = 1;

    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event HistoryRaffledWinners(address indexed winner);

    constructor(
        address vrfCoordinateV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 updateInterval
    ) VRFConsumerBaseV2(vrfCoordinateV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinateV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_interval = updateInterval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() public payable {
        if (msg.value < i_entranceFee) {
            revert Raffle_NotEnoughETHEntered();
        }
        if (s_state != RaffleState.OPEN) {
            revert Raffle_StatusFailed();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    // request the random number , 2 transaction process
    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpkeepNeeded(
                s_state,
                s_players.length,
                address(this).balance
            );
        }
        s_state = RaffleState.CLOSE;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_COMFIRMATIONS,
            i_callbackGasLimit,
            RANDOM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        bool isOpen = (RaffleState.OPEN == s_state);
        bool timePassed = (block.timestamp - s_lastTimeStamp > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_winner = winner;
        s_state = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        // transfer
        (bool isSuccess, ) = winner.call{value: address(this).balance}("");
        if (!isSuccess) {
            revert Raffle_TransactionFailed();
        }
        emit HistoryRaffledWinners(winner);
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getWinner() public view returns (address) {
        return s_winner;
    }

    function getRaffleState() public view returns(RaffleState) {
        return s_state;
    }
}
