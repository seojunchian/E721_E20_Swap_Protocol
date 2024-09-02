// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/INTPair.sol";
import "./interfaces/IERC721Receiver.sol";

/// @title ERC721-ERC20 Exchange Protocol
/// @author seojunchian
/// @notice Contract lets ERC721 owners to exchange their tokens for any ERC20 token.
contract NTPair is INTPair, IERC721Receiver {
    // erc20 transfer function
    bytes4 public immutable ERC20Transfer =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    // erc721 transfer function
    bytes4 public immutable ERC721SafeTransferFrom =
        bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256)")));

    // names are pretty obvious
    struct Pair {
        address ERC721ContractAddress;
        address ERC20ContractAddress;
        address ERC721TokenOwner;
        uint256 ERC721TokenId;
        uint256 ERC20SettedTokenValue;
    }

    // need erc20 contract address to be stored so I wouldnt ask from erc20 owner when doing swap
    mapping(address ERC721ContractAddress => mapping(uint256 ERC721TokenId => address ERC20ContractAddress))
        public ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress;
    // pair address
    mapping(address ERC721ContractAddress => mapping(uint256 ERC721TokenId => mapping(address ERC20ContractAddress => address pair)))
        public ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair;
    // pair info
    mapping(address pair => Pair) public PairAddress_To_PairInfo;

    /// @notice Lets this contract able to receive ERC721 tokens.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        emit TokenReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    /// @notice If you created a pair and given up from that idea, it lets you receive your token back.
    /// @dev Function doesnt check if contract owner of the token or not cause you cant create pair and retrieve erc721 token without it.
    function retrieveERC721Token(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) public {
        /*                 STATE VARIABLES                  */
        address _ERC20ContractAddress = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress[
                _ERC721ContractAddress
            ][_ERC721TokenId];
        address pairAddress = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
                _ERC721ContractAddress
            ][_ERC721TokenId][_ERC20ContractAddress];
        /*                    PAIR INFO                     */
        Pair memory pairInfo = PairAddress_To_PairInfo[pairAddress];
        /*                  PAIR REQUIREMENT                */
        require(pairAddress != address(0), "Pair doesnt exist");
        /*               OWNERSHIP REQUIREMENT              */
        require(
            pairInfo.ERC721TokenOwner == msg.sender,
            "Not the owner of ERC721 Token"
        );
        /*                  STATE CHANGES                   */
        ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
            _ERC721ContractAddress
        ][_ERC721TokenId][_ERC20ContractAddress] = address(0);
        /*                      EVENT                       */
        emit TokenRetrieved(
            pairInfo.ERC721TokenOwner,
            _ERC721ContractAddress,
            _ERC721TokenId
        );
        /*                     EXCHANGE                     */
        ERC721TokenTransfer(
            pairInfo.ERC721TokenOwner,
            _ERC721ContractAddress,
            _ERC721TokenId
        );
    }

    /// @notice Lets you able to create pair and set erc20 token price to exchange your erc721 token.
    /// @dev could create deterministic address with create2 and give bytecode 0x00...
    function createPair(
        address _ERC721ContractAddress,
        address _ERC20ContractAddress,
        uint256 _ERC721TokenId,
        uint256 _ERC20TokenValue
    ) public {
        /*                 STATE VARIABLES                  */
        require(
            ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
                _ERC721ContractAddress
            ][_ERC721TokenId][_ERC20ContractAddress] == address(0),
            "Pair already exists"
        );
        /*             APPROVEMENT REQUIREMENT              */
        require(
            IERC721(_ERC721ContractAddress).getApproved(_ERC721TokenId) ==
                address(this),
            "Token hasn't been approved"
        );
        /*                 PAIR CREATION                    */
        bytes32 salt = keccak256(
            abi.encodePacked(_ERC721ContractAddress, _ERC721TokenId)
        );
        address pair = address(uint160(uint256(salt)));
        /*                  STATE CHANGES                   */
        ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress[
            _ERC721ContractAddress
        ][_ERC721TokenId] = _ERC20ContractAddress;
        ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
            _ERC721ContractAddress
        ][_ERC721TokenId][_ERC20ContractAddress] = pair;
        /*                 STRUCT CHANGES                   */
        PairAddress_To_PairInfo[pair] = Pair({
            ERC721ContractAddress: _ERC721ContractAddress,
            ERC20ContractAddress: _ERC20ContractAddress,
            ERC721TokenOwner: msg.sender,
            ERC721TokenId: _ERC721TokenId,
            ERC20SettedTokenValue: _ERC20TokenValue
        });
        /*                      EVENT                       */
        emit PairCreated(
            _ERC721ContractAddress,
            _ERC721TokenId,
            _ERC20ContractAddress,
            _ERC20TokenValue,
            pair
        );
        /*                 ERC721 TRANSFER                  */
        ERC721TokenTransfer(
            address(this),
            _ERC721ContractAddress,
            _ERC721TokenId
        );
    }

    /// @notice Swap erc721 token for erc20 token.
    function swap(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) public {
        /*             VARIABLES TO GO TO PAIR              */
        address _ERC20ContractAddress = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress[
                _ERC721ContractAddress
            ][_ERC721TokenId];
        address pair = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
                _ERC721ContractAddress
            ][_ERC721TokenId][_ERC20ContractAddress];
        /*                 PAIR REQUIREMENT                 */
        require(pair != address(0), "Pair hasnt been created");
        /*                    PAIR INFO                     */
        Pair memory pairInfo = PairAddress_To_PairInfo[pair];
        /*           AFTER PRICE BEEN DETERMINED            */
        /*    REQUIREMENT FOR IF THE CONTRACT ALLOWED       */
        require(
            pairInfo.ERC20SettedTokenValue ==
                IERC20(_ERC20ContractAddress).allowance(
                    msg.sender,
                    address(this)
                ),
            "Contract hasnt been allowed to make this erc20 transfer"
        );
        /*         STATE CHANGING BEFORE TRANSFER           */
        ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
            _ERC721ContractAddress
        ][_ERC721TokenId][_ERC20ContractAddress] = address(0);
        /*                     EVENT                        */
        emit Swapped(
            _ERC721ContractAddress,
            _ERC20ContractAddress,
            msg.sender,
            pairInfo.ERC721TokenOwner,
            _ERC721TokenId,
            pairInfo.ERC20SettedTokenValue
        );
        /*                 ERC20 TRANSFER                   */
        ERC20TokenTransfer(
            msg.sender,
            pairInfo.ERC721TokenOwner,
            pairInfo.ERC20ContractAddress,
            pairInfo.ERC20SettedTokenValue
        );
        /*                 ERC721 TRANSFER                 */
        ERC721TokenTransfer(
            msg.sender,
            _ERC721ContractAddress,
            pairInfo.ERC721TokenId
        );
    }

    function ERC721TokenTransfer(
        address to,
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) private {
        (bool ERC721Success, bytes memory ERC721Data) = _ERC721ContractAddress
            .call(
                abi.encodeWithSelector(
                    ERC721SafeTransferFrom,
                    address(this),
                    to,
                    _ERC721TokenId
                )
            );
        require(
            ERC721Success &&
                (ERC721Data.length == 0 || abi.decode(ERC721Data, (bool))),
            "NT: ERC721 TRANSFER FAILED"
        );
    }

    function ERC20TokenTransfer(
        address from,
        address to,
        address _ERC20ContractAddress,
        uint256 amount
    ) private {
        (bool ERC20Success, bytes memory ERC20Data) = _ERC20ContractAddress
            .call(abi.encodeWithSelector(ERC20Transfer, from, to, amount));
        require(
            ERC20Success &&
                (ERC20Data.length == 0 || abi.decode(ERC20Data, (bool))),
            "NT: ERC20 TRAN SFER FAILED"
        );
    }

    /// @notice Lets you change erc20 price of your erc721 token
    /// @dev this function will be gone in version2
    function changeERC20TokenPrice(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId,
        uint256 _newERC20TokenPrice
    ) public {
        /*             VARIABLES TO GO TO PAIR              */
        address _ERC20ContractAddress = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress[
                _ERC721ContractAddress
            ][_ERC721TokenId];
        address pair = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
                _ERC721ContractAddress
            ][_ERC721TokenId][_ERC20ContractAddress];
        /*                 PAIR REQUIREMENT                 */
        require(pair != address(0), "Pair hasnt been created");
        /*                    PAIR INFO                     */
        Pair memory pairInfo = PairAddress_To_PairInfo[pair];
        /*              OWNERSHIP REQUIREMENT               */
        require(
            pairInfo.ERC721TokenOwner == msg.sender,
            "Not the owner of erc721 token"
        );
        /*                 STATE CHANGING                   */
        PairAddress_To_PairInfo[pair]
            .ERC20SettedTokenValue = _newERC20TokenPrice;
        /*                     EVENT                        */
        emit ERC20TokenPriceChanged(
            _ERC721ContractAddress,
            _ERC20ContractAddress,
            _ERC721TokenId,
            pairInfo.ERC20SettedTokenValue,
            _newERC20TokenPrice
        );
    }

    /// @notice Lets you return pair address.
    function returnPairAddress(
        address _ERC721ContractAddress,
        address _ERC20ContractAddress,
        uint256 _ERC721TokenId
    ) public view returns (address) {
        return
            ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
                _ERC721ContractAddress
            ][_ERC721TokenId][_ERC20ContractAddress];
    }

    /// @notice Lets you return pair info.
    function returnPairInfo(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) public view returns (Pair memory) {
        address _ERC20ContractAddress = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress[
                _ERC721ContractAddress
            ][_ERC721TokenId];
        address pairAddress = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
                _ERC721ContractAddress
            ][_ERC721TokenId][_ERC20ContractAddress];
        return PairAddress_To_PairInfo[pairAddress];
    }
}
