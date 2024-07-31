// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './IERC721.sol';
import './IERC165.sol';
import {Strings} from "./Strings.sol";

/**
 * @title remilioERC721
 * @author VLASUSDT
 * @notice ERC721 based contract to build NFT collection with Blacklist function
 * @dev You can inherit from this contract to build yours
 */
abstract contract remilioERC721 is IERC721, IERC165 {
    using Strings for uint;

    // Errors
    error ERC721RemilioDoesntExist(uint tokenId);
    error ERC721RemilioNotAuthorized(address spender, uint tokenId);
    error ERC721RemilioBlacklisted(uint tokenId);
    error ERC721RemilioTransferToZeroAddress();
    error ERC721RemilioTransferFromIncorrectOwner();
    error ERC721RemilioInvalidSender();
    error ERC721RemilioInvalidReciever();
    error ERC721RemilioApprovalCallerNotOwner(address caller);

    // Events
    event AddedToBlacklist(uint indexed tokenId);
    event RemovedFromBlacklist(uint indexed tokenId);
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // State Variables
    string public _name; 
    string public _symbol;
    address private admin;

    mapping(bytes4 => bool) private _supportedInterfaces;
    mapping(uint => address) public _owners;
    mapping(address => uint) public _balances;
    mapping(uint => address) public _tokenApprovals;
    mapping(address => mapping(address => bool)) public _operatorApprovals; 
    mapping(uint => bool) private blacklist;

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != admin) revert ERC721RemilioNotAuthorized(msg.sender, 0);
        _;
    }

    // Constructor
    /**
     * @dev Initializes the contract with a name, symbol, and admin address.
     * @param name_ Name of the token
     * @param symbol_ Symbol of the token
     * @param _admin Address of the contract admin
     */
    constructor(string memory name_, string memory symbol_, address _admin) {
        admin = _admin;
        _name = name_;
        _symbol = symbol_;
        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC165).interfaceId);
    }

    /**
     * @notice Checks if the contract implements the specified interface.
     * @param interfaceId The interface identifier, as specified in ERC165
     * @return True if the contract implements the specified interface, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the supported interface.
     * @param interfaceId The interface identifier, as specified in ERC165
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "Invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    // External/Public Functions

    /**
     * @notice Returns the balance of the given address.
     * @param owner Address to query the balance of
     * @return Balance of the given address
     */
    function balanceOf(address owner) public view virtual returns (uint) {
        return _balances[owner];
    }

    /**
     * @notice Returns the owner of the specified token ID.
     * @param tokenId ID of the token to query the owner of
     * @return Address currently marked as the owner of the given token ID
     */
    function ownerOf(uint tokenId) public view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @notice Returns the name of the token.
     * @return Name of the token
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @notice Returns the symbol of the token.
     * @return Symbol of the token
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Returns the URI for a given token ID.
     * @param tokenId ID of the token to query
     * @return URI of the given token ID
     */
    function tokenURI(uint tokenId) public view virtual returns (string memory) {
        _requiredOwned(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @notice Returns the approved address for a token ID, or zero if no address is set.
     * @param tokenId ID of the token to query the approval of
     * @return Address currently approved for the given token ID
     */
    function getApproved(uint tokenId) public view virtual returns (address) {
        return _getApproved(tokenId);
    }

    /**
     * @notice Adds a token to the blacklist.
     * @dev Only callable by the contract owner
     * @param tokenId ID of the token to be blacklisted
     * @return True if the operation was successful
     */
    function addToBlacklist(uint tokenId) public onlyOwner returns (bool) {
        address owner = _requiredOwned(tokenId);
        blacklist[tokenId] = true;
        emit AddedToBlacklist(tokenId);
        return true;
    }

    /**
     * @notice Removes a token from the blacklist.
     * @dev Only callable by the contract owner
     * @param tokenId ID of the token to be removed from the blacklist
     */
    function removeFromBlacklist(uint tokenId) public onlyOwner {
        address owner = _requiredOwned(tokenId);
        blacklist[tokenId] = false;
        emit RemovedFromBlacklist(tokenId);
    }

    /**
     * @notice Checks if a token is blacklisted.
     * @param tokenId ID of the token to check
     * @return True if the token is blacklisted, false otherwise
     */
    function _isTokenBlacklisted(uint tokenId) internal view returns (bool) {
        return blacklist[tokenId];
    }

    /**
     * @notice Checks if an operator is approved for all tokens of a given owner.
     * @param owner Address of the token owner
     * @param operator Address of the operator to check
     * @return True if the operator is approved, false otherwise
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice Approves or disapproves an operator for all tokens of the sender.
     * @param operator Address of the operator to be approved or disapproved
     * @param approved True if the operator is approved, false otherwise
     */
    function setApprovalForAll(address operator, bool approved) public {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Transfers a token from one address to another.
     * @param from Address of the current owner of the token
     * @param to Address to receive the ownership of the given token ID
     * @param tokenId ID of the token to be transferred
     */
    function transferFrom(address from, address to, uint tokenId) public virtual {
        if (to == address(0)) revert ERC721RemilioTransferToZeroAddress();
        address prevOwner = _update(to, tokenId, msg.sender);
        if (from != prevOwner) revert ERC721RemilioTransferFromIncorrectOwner();
    }

    /**
     * @notice Approves an address to transfer the given token ID.
     * @param to Address to be approved for the given token ID
     * @param tokenId ID of the token to be approved
     */
    function approve(address to, uint tokenId) public virtual {
        _approve(to, tokenId, true);
    }

    /**
     * @notice Mints a new token with the given ID and assigns it to `to`.
     * @dev Reverts if the receiver address is zero.
     * @param to Address to receive the minted token
     * @param tokenId ID of the token to mint
     */
    function mint(address to, uint tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721RemilioInvalidReciever();
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner != address(0)) {
            revert ERC721RemilioInvalidSender();
        }
    }

    /**
     * @notice Burns a token with the given ID.
     * @param tokenId ID of the token to burn
     */
    function burn(uint tokenId) public virtual {
        address owner = _requiredOwned(tokenId);
        _update(address(0), tokenId, owner);
    }

    // Internal Functions

    /**
     * @notice Checks if an address is authorized to manage a token.
     * @param owner Address of the token owner
     * @param spender Address to check for authorization
     * @param tokenId ID of the token to check
     * @return True if the spender is authorized to manage the token, false otherwise
     */
    function _isAuthorized(address owner, address spender, uint tokenId) internal view virtual returns (bool) {
        if (spender == address(0)) revert ERC721RemilioNotAuthorized(spender, tokenId);
        return owner == spender || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender;
    }

    /**
     * @notice Updates the ownership and balances when a token is transferred.
     * @param to Address to receive the ownership of the given token ID
     * @param tokenId ID of the token to be transferred
     * @param auth Address authorized to transfer the token
     * @return Address of the previous owner of the token
     */
    function _update(address to, uint tokenId, address auth) internal virtual returns (address) {
        address from = _owners[tokenId];
        if (from == address(0)) revert ERC721RemilioDoesntExist(tokenId);
        if (!_isAuthorized(from, auth, tokenId)) revert ERC721RemilioNotAuthorized(auth, tokenId);
        if (_isTokenBlacklisted(tokenId)) revert ERC721RemilioBlacklisted(tokenId);

        _approve(address(0), tokenId, false);
        _balances[from] -= 1;
        if (to != address(0)) {
            _balances[to] += 1;
            _owners[tokenId] = to;
        }
        emit Transfer(from, to, tokenId);
        return from;
    }

    /**
     * @notice Approves an address to transfer the given token ID.
     * @param to Address to be approved for the given token ID
     * @param tokenId ID of the token to be approved
     * @param emitEvent True if the approval event should be emitted
     */
    function _approve(address to, uint tokenId, bool emitEvent) internal virtual {
        address owner = _requiredOwned(tokenId);
        if (msg.sender != owner) revert ERC721RemilioApprovalCallerNotOwner(msg.sender);
        _tokenApprovals[tokenId] = to;
        if (emitEvent) {
            emit Approval(owner, to, tokenId);
        }
    }

    /**
     * @notice Returns the base URI for computing {tokenURI}. If set, the resulting URI for each token will be the concatenation of the `baseURI` and the `tokenId`. Empty by default, can be overridden in child contracts.
     * @return Base URI string
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @notice Checks if a token ID exists and returns its owner address.
     * @param tokenId ID of the token to check
     * @return Address of the owner of the token
     */
    function _requiredOwned(uint tokenId) internal view virtual returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert ERC721RemilioDoesntExist(tokenId);
        return owner;
    }

    /**
     * @notice Returns the approved address for a token ID, or zero if no address is set.
     * @param tokenId ID of the token to query the approval of
     * @return Address currently approved for the given token ID
     */
    function _getApproved(uint tokenId) internal view virtual returns (address) {
        _requiredOwned(tokenId);
        return _tokenApprovals[tokenId];
    }

    /**
     * @notice Approves or disapproves an operator for all tokens of the owner.
     * @param owner Address of the token owner
     * @param operator Address of the operator to be approved or disapproved
     * @param approved True if the operator is approved, false otherwise
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        if (owner != msg.sender) revert ERC721RemilioApprovalCallerNotOwner(msg.sender);
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
}
