// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract SubscriptionManager is VRFConsumerBaseV2 {

    uint64 public subscriptionId;
    address public owner;

    LinkTokenInterface LinkToken = LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;
    VRFCoordinatorV2Interface COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);

    bytes32 s_keyHash = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
    uint32 callbackGasLimit = 40000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

    uint256 public randomNum;
    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }

    constructor() VRFConsumerBaseV2(vrfCoordinator){
        subscriptionId = COORDINATOR.createSubscription();
        COORDINATOR.addConsumer(subscriptionId, address(this));
        owner = msg.sender;
    }

    function requestRandomNumber() external onlyOwner returns(uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(s_keyHash,subscriptionId,requestConfirmations,callbackGasLimit,numWords);
    }

    function fulfillRandomWords(uint256 , uint256[] memory randomWords) internal override{
        randomNum = (randomWords[0] % 20)+1;
    }

    function addConsumer(address _consumer) external onlyOwner {
        COORDINATOR.addConsumer(subscriptionId, _consumer);
    }

    function removeConsumer(address _consumer) external onlyOwner {
        COORDINATOR.removeConsumer(subscriptionId, _consumer);
    }

    function cancelSubscription(address _to) external onlyOwner{
        COORDINATOR.cancelSubscription(subscriptionId, _to);
    }

    function topUpSubscription(uint256 _amount) external onlyOwner{
        bool success = LinkToken.transferAndCall(vrfCoordinator, _amount, abi.encode(subscriptionId));
        require(success, "topUp failed!");
    }
}
