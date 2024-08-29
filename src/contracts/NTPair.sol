// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./interfaces/INTPair.sol";
import "./interfaces/IERC721Receiver.sol";

contract NTPair is INTPair, IERC721Receiver {
    // before deployment change double quoto to one quoto
    bytes4 public immutable ERC20Transfer =
        bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
    bytes4 public immutable ERC721SafeTransferFrom =
        bytes4(keccak256(bytes("safeTransferFrom(address,address,uint256)")));

    struct Pair {
        address ERC721ContractAddress;
        address ERC20ContractAddress;
        address ERC721TokenOwner;
        uint256 ERC721TokenId;
        uint256 ERC20SettedTokenValue;
    }

    mapping(address ERC721ContractAddress => mapping(uint256 ERC721TokenId => address ERC20ContractAddress))
        public ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress;
    mapping(address ERC721ContractAddress => mapping(uint256 ERC721TokenId => mapping(address ERC20ContractAddress => address pair)))
        public ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair;
    mapping(address pair => Pair) public PairAddress_To_PairInfo;

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        emit TokenReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }

    function retrieveERC721Token(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) public {
        address _ERC20ContractAddress = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress[
                _ERC721ContractAddress
            ][_ERC721TokenId];
        address pairAddress = ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
                _ERC721ContractAddress
            ][_ERC721TokenId][_ERC20ContractAddress];
        Pair memory pairInfo = PairAddress_To_PairInfo[pairAddress];
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

    function createPair(
        address _ERC721ContractAddress,
        address _ERC20ContractAddress,
        uint256 _ERC721TokenId,
        uint256 _ERC20TokenValue
    ) public {
        require(
            ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
                _ERC721ContractAddress
            ][_ERC721TokenId][_ERC20ContractAddress] == address(0),
            "Pair already exists"
        );
        require(
            IERC721(_ERC721ContractAddress).ownerOf(_ERC721TokenId) ==
                address(this),
            "Token hasn't been sent to this contract"
        );
        // requirement for sended erc721token is in fact a erc721 contract address
        /* require(supportsInterface(type(IERC721).interfaceId)); */
        // pair creation
        bytes32 salt = keccak256(
            abi.encodePacked(_ERC721ContractAddress, _ERC721TokenId)
        );
        address pair = address(uint160(uint256(salt)));
        // on-contract data
        ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress[
            _ERC721ContractAddress
        ][_ERC721TokenId] = _ERC20ContractAddress;
        ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
            _ERC721ContractAddress
        ][_ERC721TokenId][_ERC20ContractAddress] = pair;
        PairAddress_To_PairInfo[pair] = Pair({
            ERC721ContractAddress: _ERC721ContractAddress,
            ERC20ContractAddress: _ERC20ContractAddress,
            ERC721TokenOwner: msg.sender,
            ERC721TokenId: _ERC721TokenId,
            ERC20SettedTokenValue: _ERC20TokenValue
        });
        emit PairCreated(
            _ERC721ContractAddress,
            _ERC721TokenId,
            _ERC20ContractAddress,
            _ERC20TokenValue,
            pair
        );
    }

    function swap(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) public {
        /*             VARIBALES TO GO TO PAIR              */
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
            "Contract hasnt been allowed to make this transfer on erc20 owner behalf"
        );
        /*         STATE CHANGING BEFORE TRANSFER           */
        ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress_To_Pair[
            _ERC721ContractAddress
        ][_ERC721TokenId][_ERC20ContractAddress] = address(0);
        /*                    EXCHANGE                      */
        emit Swapped(
            _ERC721ContractAddress,
            _ERC20ContractAddress,
            msg.sender,
            pairInfo.ERC721TokenOwner,
            _ERC721TokenId,
            pairInfo.ERC20SettedTokenValue
        );
        ERC20TokenTransfer(
            msg.sender,
            pairInfo.ERC721TokenOwner,
            pairInfo.ERC20ContractAddress,
            pairInfo.ERC20SettedTokenValue
        );
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

    function changeERC20TokenPrice(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId,
        uint256 _newERC20TokenPrice
    ) public {
        /*             VARIBALES TO GO TO PAIR              */
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
        emit ERC20TokenPriceChanged(
            _ERC721ContractAddress,
            _ERC20ContractAddress,
            _ERC721TokenId,
            pairInfo.ERC20SettedTokenValue,
            _newERC20TokenPrice
        );
    }

    function returnERC20Token(
        address _ERC721ContractAddress,
        uint256 _ERC721TokenId
    ) public view returns (address) {
        return
            ERC721ContractAddress_To_ERC721TokenId_To_ERC20ContractAddress[
                _ERC721ContractAddress
            ][_ERC721TokenId];
    }

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
}
