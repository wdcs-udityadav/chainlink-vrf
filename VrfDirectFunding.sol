// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";

contract VrfDirectFunding is VRFV2WrapperConsumerBase, ConfirmedOwner {

    address link = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address vrfWrapper= 0x99aFAf084eBA697E584501b8Ed2c0B37Dd136693;
    
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;

    struct Request{
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }
    mapping(uint256 => Request) requests;

    event RequestSent(uint256 indexed requestId, uint256 indexed  numWords);
    event RequestFulfilled(uint256 indexed requestId, uint256[] randomWords, uint256 amountPaid);

    constructor() VRFV2WrapperConsumerBase(link, vrfWrapper) ConfirmedOwner(msg.sender){
    }

    function requestRandomness() external onlyOwner returns(uint256 requestId) {
        requestId = requestRandomness(callbackGasLimit, requestConfirmations, numWords);

        requests[requestId] = Request({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            fulfilled: false,
            randomWords: new uint256[](0)
        });

        emit RequestSent(requestId, numWords);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override{
        require(requests[_requestId].paid > 0, "invalid requestId");
        requests[_requestId].fulfilled = true;
        requests[_requestId].randomWords = _randomWords;

        emit RequestFulfilled(_requestId, _randomWords, requests[_requestId].paid);
    }

    function getRequestStatus(uint256 requestId) external view returns(uint256,bool,uint256[] memory) {
        require(requests[requestId].paid > 0, "invalid requestId");
        Request memory req = requests[requestId];
        return (req.paid, req.fulfilled,req.randomWords);
    }

    function withdrawLink() onlyOwner external {
        uint256 linkBalance = LINK.balanceOf(address(this));
        require(linkBalance > 0, "insufficient balance");
        bool success = LINK.transfer(msg.sender,linkBalance);
        require(success, "withdrawl failed!");
    }
}
