// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract LetsLoveLain is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished,
        AllowListOnly
    }

    Status public status;
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 3;
    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant PRICE = 0.003 * 10**18; // 0.003 ETH

    mapping(address => uint256) public allowlist;

    event Minted(address minter, uint256 amount);
    event StatusChanged(Status status);
    event BaseURIChanged(string newBaseURI);

    constructor(string memory initBaseURI) ERC721A("LetsLoveLain", "Lain") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "Not started yet");
        require(tx.origin == msg.sender, "No contract calls allowed");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "Max mint per address."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Insufficient remaining quantity"
        );

        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);

        emit Minted(msg.sender, quantity);
    }

    function allowlistMint(uint256 quantity) external payable {
        require(allowlist[msg.sender] > 0, "Not on the Whitelist");
        require(
            status == Status.Started || status == Status.AllowListOnly,
            "Not started yet"
        );
        require(tx.origin == msg.sender, "No contract calls allowed");
        require(quantity <= allowlist[msg.sender], "stop!");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Insufficient remaining quantity"
        );
        allowlist[msg.sender] = allowlist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(PRICE * quantity);

        emit Minted(msg.sender, quantity);
    }

    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(addresses.length == numSlots.length, "Wrong address");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "wrong price");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
        emit StatusChanged(status);
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
        emit BaseURIChanged(newBaseURI);
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "U really love Lain!");
    }
}
