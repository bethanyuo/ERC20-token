pragma solidity 0.5.0;

//import "@openzeppelin/contracts/token/ERC721/ERC721Full.sol";
//import "./node_modules/@openzeppelin/contracts/token/ERC721/ERC721Full.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.3.0-rc.3/contracts/token/ERC721/ERC721Full.sol";


contract GiftLottery is ERC721Full {

    struct Gift {
        string title;
        string description;
        string tokenURI;
    }

    address private owner;
    address[] private participants;
    uint256 private endTime;

    uint[] private allTokens;

    mapping(address => uint256[]) public _ownedTokens;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    //mapping (address => Counters.Counter) private _ownedTokensCount;


    mapping(uint256 => Gift) giftIdToGift;

    event CreateGift(address indexed participant, uint256 giftId);
    event ReceivedGift(address indexed winner, uint256 giftId);

    constructor() ERC721Full("GiftLottery", "GLT") public {
        endTime = now + 1 minutes;
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Must be the Contract Owner");
        _;
    }

    modifier onlyOnce {
        //require(msg.sender == owner, "Must be the Contract Owner");
        for(uint i = 1; i < _tokenIds.current(); i++) {
            if (allTokens.length > participants.length) {

                require(i == participants.length, "Too Many Gifts: Cannot be Evenly Distributed");
                //i = participants.length;
            }
        }
        _;
    }

    function createGift(string calldata _title, string calldata _description, string calldata tokenURI) external {
        require(endTime >= now, "Creation Time is Over");

        //uint256 index = allTokens.length.add(1);
        _tokenIds.increment();
        uint256 index = _tokenIds.current();
        _mint(owner,index);
        _setTokenURI(index, tokenURI);
        giftIdToGift[index] = Gift(_title,_description,tokenURI);
        participants.push(msg.sender);
        allTokens.push(index);
        emit CreateGift(msg.sender,index);
    }

    function pseudoRandom(uint256 _giftId) private view returns(uint) {
        Gift memory gift = giftIdToGift[_giftId];

        return uint(keccak256(abi.encodePacked(gift.title, gift.description, gift.tokenURI, _giftId))) % participants.length;
    }

    function distributeGifts() public onlyOwner onlyOnce {
        for(uint i = 1; i < _tokenIds.current(); i++) {

            uint randomAddress = pseudoRandom(i);

            address winner = participants[randomAddress];

            require(_ownedTokens[winner].length <= 1, "Should not have more than one gift");

            transferFrom(msg.sender, winner, i);

            emit ReceivedGift(winner, i);

        }
    }
}
