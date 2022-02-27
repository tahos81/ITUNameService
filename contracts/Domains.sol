// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import { StringUtils } from "./libraries/StringUtils.sol";
import {Base64} from "./libraries/Base64.sol";

import "hardhat/console.sol";

contract Domains is ERC721URIStorage {

    error Unauthorized();
    error AlreadyRegistered();  
    error InvalidName(string name);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;
    address payable public owner;

    string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><g fill-rule="evenodd"><path stroke="#979797" stroke-linecap="round" stroke-width="2" d="M30.992 54.555v5.395m-2.373-47.826L24 5m10 7.124L38.62 5"/><circle cx="48" cy="33" r="12" fill="#B4DFFB"/><circle cx="15" cy="33" r="12" fill="#B4DFFB"/><path fill="#FFAF40" d="M22 19.999A8.999 8.999 0 0 1 31 11c4.97 0 9 4.02 9 8.999V43H22V19.999Z"/><path fill="#595959" d="M22 43h18v6c0 3.314-2.695 6-5.994 6h-6.012C24.684 55 22 52.307 22 49v-6Zm0-8h18v4H22zm0-8h18v4H22z"/></g><defs><linearGradient id="a" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#b)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = '</text></svg>';

    mapping(string => address) public domains;
    mapping(string => string) public records; 
    mapping (uint => string) public names;

    constructor(string memory _tld) payable ERC721("ITU Name Service", "INS") {
        owner = payable(msg.sender);
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    function price(string calldata name) public pure returns (uint) {
        uint len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 0.5 ether;
        } else if (len == 4) {
            return 0.3 ether;
        } else {
            return 0.1 ether;
        }
    }

    function register(string calldata name) public payable {
        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!valid(name)) revert InvalidName(name);

        uint _price = price(name);
        require(msg.value >= _price);

        string memory _name = string(abi.encodePacked(name, ".", tld));
        string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log("Registering %s.%s on the contract with tokenId %d", name, tld, newRecordId);

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name,
                        '", "description": "A domain on the ITU Name Service", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '","length":"',
                        strLen,
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));

        console.log("\n--------------------------------------------------------");
	    console.log("Final tokenURI:", finalTokenUri);
	    console.log("--------------------------------------------------------\n");
        
        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);

        domains[name] = msg.sender;
        
        names[newRecordId] = name;

        _tokenIds.increment();
    }

    function valid(string calldata name) public pure returns(bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
    }

    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name) public view returns (string memory) {
        return records[name];
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    } 
}