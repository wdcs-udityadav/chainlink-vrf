// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract VrfExample is VRFConsumerBaseV2 {

    uint64 s_subscriptionId;
    address s_owner;
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    bytes32 s_keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

    uint256 constant ROLL_IN_PROGRESS = 99;

    mapping(uint256 => address) s_rollers;
    mapping(address => uint256) s_results;

    event DiceRolled(address indexed roller, uint256 indexed requestId);
    event DiceLanded(uint256 indexed  requestId,uint256 indexed d20Value);

    modifier onlyOwner () {
        require(msg.sender == s_owner);
        _;
    }

    constructor(uint64 _subsId) VRFConsumerBaseV2(vrfCoordinator){
        s_owner = msg.sender;
        s_subscriptionId = _subsId;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    }

    function rollDice(address _roller) external onlyOwner returns(uint256 requestId) {
        require(s_results[_roller] == 0, "dice already rolled");
        requestId = COORDINATOR.requestRandomWords(s_keyHash,s_subscriptionId,requestConfirmations,callbackGasLimit,numWords);
        s_rollers[requestId] = _roller;

        s_results[_roller] = ROLL_IN_PROGRESS;
        emit DiceRolled(_roller, requestId);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override{
        uint256 d20Value = (randomWords[0] % 20)+1;

        s_results[s_rollers[requestId]] = d20Value;

        emit DiceLanded(requestId, d20Value);
    }

    function getHousename(uint256 _id) private pure returns (string memory){
        string[20] memory houseNames = [
            "Targaryen",
            "Lannister",
            "Stark",
            "Tyrell",
            "Baratheon",
            "Martell",
            "Tully",
            "Bolton",
            "Greyjoy",
            "Arryn",
            "Frey",
            "Mormont",
            "Tarley",
            "Dayne",
            "Umber",
            "Valeryon",
            "Manderly",
            "Clegane",
            "Glover",
            "Karstark"
        ];

        return houseNames[_id-1];
    }

    function house(address _player) external view returns(string memory)  {
        require(s_results[_player] != 0, "dice not rolled");
        require(s_results[_player] != ROLL_IN_PROGRESS, "ROLL_IN_PROGRESS");

        return getHousename(s_results[_player]);
    }
}
