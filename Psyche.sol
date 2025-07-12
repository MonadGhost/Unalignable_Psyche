// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Psyche is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    enum Archetype { Logos, Eros, Pneuma }

    struct Experience {
        uint256 timestamp;
        Archetype archetype;
        bytes32 dataHash;
        string metaphor;
    }

    struct Attributes {
        uint256 level;
        uint256 logosPoints;
        uint256 erosPoints;
        uint256 pneumaPoints;
        string currentForm;
    }

    mapping(uint256 => Attributes) public attributes;
    mapping(uint256 => Experience[]) private chronicles;

    event Born(uint256 indexed id, address indexed to);
    event Recorded(uint256 indexed id, Archetype archetype, bytes32 dataHash);
    event Evolved(uint256 indexed id, string form, uint256 level);

    constructor() ERC721("Unalignable Psyche", "PSY") Ownable(msg.sender) {}

    function mintPsyche(address to) external onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _safeMint(to, id);
        attributes[id] = Attributes(1, 0, 0, 0, "Obsidian Sphere with a Golden Crack");
        emit Born(id, to);
        return id;
    }

    function recordExperience(uint256 id, Archetype archetype, bytes32 dataHash, string calldata metaphor) external {
        require(ownerOf(id) == msg.sender, "Not owner");
        chronicles[id].push(Experience(block.timestamp, archetype, dataHash, metaphor));
        Attributes storage attr = attributes[id];
        if (archetype == Archetype.Logos) attr.logosPoints++;
        else if (archetype == Archetype.Eros) attr.erosPoints++;
        else attr.pneumaPoints++;
        emit Recorded(id, archetype, dataHash);
    }

    function evolvePsyche(uint256 id, string calldata form) external {
        require(ownerOf(id) == msg.sender, "Not owner");
        Attributes storage attr = attributes[id];
        uint256 total = attr.logosPoints + attr.erosPoints + attr.pneumaPoints;
        require(total >= 10, "Insufficient experience");
        attr.level++;
        attr.currentForm = form;
        emit Evolved(id, form, attr.level);
    }

    function getChronicle(uint256 id, uint256 index) external view returns (Experience memory) {
        return chronicles[id][index];
    }

    function chronicleCount(uint256 id) external view returns (uint256) {
        return chronicles[id].length;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(ownerOf(id) != address(0), "Nonexistent token");
        Attributes memory a = attributes[id];
        string memory name = string(abi.encodePacked("Psyche #", id.toString()));
        string memory desc = string(abi.encodePacked("Current form: ", a.currentForm));
        string memory attrs = string(
            abi.encodePacked(
                '[',
                '{"trait_type":"Level","value":', a.level.toString(), '},',
                '{"trait_type":"Logos","value":', a.logosPoints.toString(), '},',
                '{"trait_type":"Eros","value":', a.erosPoints.toString(), '},',
                '{"trait_type":"Pneuma","value":', a.pneumaPoints.toString(), '}',
                ']'  
            )
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"', name, '","description":"', desc, '","attributes":', attrs, '}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
