// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// Dev imports. This only works on a local dev network
// and will not work on any test or main livenets.
import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint public interval;
    uint public lastTimeStamp;
    int256 public currentPrice;

    AggregatorV3Interface public priceFeed ;

    // IPFS URIs for the dynamic nft graphics/metadata.
    string[] bullUrisIpfs = [
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"
        
    ];
    string[] bearUrisIpfs = [
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];


    event TokensUpdated(string marketTrend);

    constructor (uint updateInterval, address _priceFeed) ERC721("BullBear", "MTK") {
        // Sets the keeper update interval
        interval= updateInterval;
        lastTimeStamp = block.timestamp;


        // Sets the price feed address to
        // BTC/USD Price Feed Contract address on Rinkeby: https://rinkeby.etherscan.io/address/0xECe365B379E1dD183B20fc5f022230C044d51404
        // or the MockPriceFeed contract
        priceFeed= AggregatorV3Interface(_priceFeed);

        currentPrice = getLatestPrice();

    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        // Defaults to gamer bull NFT Image
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);
    }



    function checkUpkeep(bytes calldata ) external view override returns ( bool upkeepNeeded, bytes memory){
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
  }
    function performUpkeep(bytes calldata ) external override {
        if ((block.timestamp - lastTimeStamp) > interval){
            lastTimeStamp = block.timestamp;
            int latestPrice = getLatestPrice();

            if(latestPrice == currentPrice){
                return;
            }
        if(latestPrice < currentPrice){
                //  bear
                updateAllTokenUris("bears");
            } else{
                // bull
                updateAllTokenUris("bull");
            }


            currentPrice = latestPrice;
        } else {
            // Interval not elasped no upkeep
        }
       
    }



        /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // An example of what the return value from a price feed looks like is: int256 3034715771688 
        return price;
    }

    function updateAllTokenUris(string memory trend) internal {
        if (compareString("bear", trend)){
            for (uint  i=0;i < _tokenIdCounter.current(); i++){
                _setTokenURI(i, bearUrisIpfs[0]);
            }
        } else {
                 for (uint  i=0;i < _tokenIdCounter.current(); i++){
                _setTokenURI(i, bullUrisIpfs[0]);
            }
        }
        emit TokensUpdated(trend);
    }

    function setInterval (uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }


    function setPriceFeed (address newFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(newFeed);
    }

// Helpers

function compareString(string memory a , string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));

}

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}