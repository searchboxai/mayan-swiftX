// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
// Permit2-related imports

import "permit2/Permit2.sol";
import "permit2/EIP712.sol";
import {PermitHash} from "permit2/libraries/PermitHash.sol";
import "permit2/libraries/SignatureVerification.sol";
import "permit2/interfaces/IAllowanceTransfer.sol";

// Project-specific interfaces
import "./interfaces/IMayanSwift.sol";
import "./interfaces/IMayanSwiftX.sol";
import "./interfaces/IMayanForwarder.sol";
import "./SignatureChecker.sol";

// OpenZeppelin imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SignatureChecker as OZSignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

// Pyth Network imports
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "./SignatureChecker.sol";

contract MayanSwiftX is IMayanSwiftX, SignatureChecker, ReentrancyGuard {
    using PermitHash for ISignatureTransfer.PermitTransferFrom;

    Permit2 public permit2;
    IPyth public pyth;

    address public immutable MAYAN_ORDER_CONTRACT;
    address public immutable MAYAN_FORWARDER_CONTRACT;
    address public immutable owner;

    uint256 public PROTOCOL_FEE;

    mapping(bytes32 => bool) public cancelledOrders;
    mapping(bytes32 => uint8) public recurringExecutedCount;

    constructor(
        address _permit2,
        address _mayanOrderContract,
        address _mayanForwarderContract,
        address _pyth,
        address _owner
    ) {
        permit2 = Permit2(_permit2);
        MAYAN_ORDER_CONTRACT = _mayanOrderContract;
        MAYAN_FORWARDER_CONTRACT = _mayanForwarderContract;
        pyth = IPyth(_pyth);
        owner = _owner;
    }

    function setFee(uint256 _fee) public {
        require(msg.sender == owner, "");
        PROTOCOL_FEE = _fee;
    }

    function execute(
        TransferPayload calldata transferPayload,
        OrderPayload memory orderPayload,
        bytes[] memory updateData
    ) public payable nonReentrant {
        bytes32 orderHash = keccak256(abi.encode(orderPayload));
        if (cancelledOrders[orderHash]) {
            revert CancelledOrder();
        }
        if (orderHash != transferPayload.witness) {
            revert WitnessMismatch();
        }

        if (transferPayload.permit.nonce != orderPayload.nonce) {
            revert InvalidOrderNonce();
        }

        bool shouldProcess;
        if (orderPayload.customOrderType == CustomOrderType.PriceOrder) {
            uint256 fee = pyth.getUpdateFee(updateData);
            pyth.updatePriceFeeds{value: fee}(updateData);
            PythStructs.Price memory price = pyth.getPriceNoOlderThan(orderPayload.oracleFeedId, 60);
            shouldProcess = handlePriceOrder(orderPayload, price.price);
            if (!shouldProcess) return;
        }

        if (orderPayload.customOrderType == CustomOrderType.TimeOrder) {
            shouldProcess = handleTimeOrder(orderPayload);
            if (!shouldProcess) return;
        }

        if (shouldProcess) {
            permit2.permitWitnessTransferFrom(
                transferPayload.permit,
                transferPayload.transferDetails,
                transferPayload.owner,
                transferPayload.witness,
                transferPayload.witnessTypeString,
                transferPayload.signature
            );

            IERC20(orderPayload.tokenIn).transfer(msg.sender, PROTOCOL_FEE);

            uint256 amountInWithFee = orderPayload.amountIn - PROTOCOL_FEE;

            IERC20(orderPayload.tokenIn).approve(MAYAN_FORWARDER_CONTRACT, amountInWithFee);

            PermitParams memory permitParams;

            bytes memory protocolData = abi.encodeWithSelector(
                IMayanSwift.createOrderWithToken.selector,
                orderPayload.tokenIn,
                amountInWithFee,
                orderPayload.orderParams
            );

            IMayanForwarder(MAYAN_FORWARDER_CONTRACT).forwardERC20(
                orderPayload.tokenIn, amountInWithFee, permitParams, MAYAN_ORDER_CONTRACT, protocolData
            );
        }
    }

    function execute(
        AllowancePayload memory allowancePayload,
        OrderPayload memory orderPayload,
        bytes[] memory updateData
    ) public payable nonReentrant {
        bytes32 orderHash = keccak256(abi.encode(orderPayload));

        if (cancelledOrders[orderHash]) {
            revert CancelledOrder();
        }

        if (orderHash != allowancePayload.orderHash) {
            revert WitnessMismatch();
        }

        bytes32 rawMsgHash = keccak256(abi.encode(address(this), block.chainid, orderHash));

        bytes32 msgHash = ECDSA.toEthSignedMessageHash(rawMsgHash);

        if (
            !OZSignatureChecker.isValidSignatureNow(
                allowancePayload.owner, msgHash, allowancePayload.orderPayloadSignature
            )
        ) {
            revert FailedSignatureVerification();
        }

        bool shouldProcess;
        if (orderPayload.customOrderType == CustomOrderType.RecurringOrder) {
            uint256 fee = pyth.getUpdateFee(updateData);
            pyth.updatePriceFeeds{value: fee}(updateData);
            PythStructs.Price memory price = pyth.getPriceNoOlderThan(orderPayload.oracleFeedId, 60);
            shouldProcess = handleRecurringOrder(orderPayload, orderHash, price.price);
            if (!shouldProcess) return;
        }

        permit2.permit(allowancePayload.owner, allowancePayload.permitSingle, allowancePayload.allowancePayloadSig);

        (uint160 amount,,) = permit2.allowance(allowancePayload.owner, allowancePayload.tokenIn, address(this));
        uint256 tradeAmount = (orderPayload.amountIn / orderPayload.noOfOrders);

        if (shouldProcess && amount >= tradeAmount) {
            permit2.transferFrom(allowancePayload.owner, address(this), uint160(tradeAmount), allowancePayload.tokenIn);
        }

        IERC20(orderPayload.tokenIn).transfer(msg.sender, PROTOCOL_FEE);
        tradeAmount -= PROTOCOL_FEE;
        IERC20(orderPayload.tokenIn).approve(MAYAN_FORWARDER_CONTRACT, tradeAmount);

        PermitParams memory permitParams;

        bytes memory protocolData = abi.encodeWithSelector(
            IMayanSwift.createOrderWithToken.selector, orderPayload.tokenIn, tradeAmount, orderPayload.orderParams
        );

        IMayanForwarder(MAYAN_FORWARDER_CONTRACT).forwardERC20(
            orderPayload.tokenIn, tradeAmount, permitParams, MAYAN_ORDER_CONTRACT, protocolData
        );
    }

    function handlePriceOrder(OrderPayload memory orderPayload, int64 price) internal returns (bool shouldProcess) {
        handleTimeOrder(orderPayload);

        if (price < orderPayload.minExecutionPrice || price > orderPayload.maxExecutionPrice) {
            revert OutsideExecutionPrice();
        }

        return true;
    }

    function handleTimeOrder(OrderPayload memory orderPayload) internal returns (bool shouldProcess) {
        if (block.timestamp < orderPayload.minExecutionTime || block.timestamp > orderPayload.maxExecutionTime) {
            revert OutsideExecutionWindow();
        }
        return true;
    }

    function cancelOrder(AllowancePayload memory allowancePayload, bytes32 orderHash) public {
        bytes32 rawMsgHash = keccak256(abi.encode(address(this), block.chainid, orderHash));

        bytes32 msgHash = ECDSA.toEthSignedMessageHash(rawMsgHash);

        if (!OZSignatureChecker.isValidSignatureNow(msg.sender, msgHash, allowancePayload.orderPayloadSignature)) {
            revert FailedSignatureVerification();
        }

        cancelledOrders[orderHash] = true;

        emit OrderCancelled(orderHash, msg.sender);
    }

    function cancelOrder(TransferPayload calldata transferPayload) public {
        bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, transferPayload.permit.permitted));

        bytes32 dataHash = keccak256(
            abi.encode(
                WITNESS_TYPEHASH,
                tokenPermissions,
                address(this),
                transferPayload.permit.nonce,
                transferPayload.permit.deadline,
                transferPayload.witness
            )
        );
        bytes32 msgHash = keccak256(abi.encodePacked("\x19\x01", permit2.DOMAIN_SEPARATOR(), dataHash));

        SignatureVerification.verify(transferPayload.signature, msgHash, msg.sender);

        cancelledOrders[transferPayload.witness] = true;

        emit OrderCancelled(transferPayload.witness, msg.sender);
    }

    function handleRecurringOrder(OrderPayload memory orderPayload, bytes32 orderHash, int64 price)
        internal
        returns (bool shouldProcess)
    {
        handleTimeOrder(orderPayload);
        handlePriceOrder(orderPayload, price);
        uint8 executedCount = recurringExecutedCount[orderHash];
        if (executedCount >= orderPayload.noOfOrders) {
            revert AllOrdersExecuted();
        }

        uint256 iteration = executedCount + 1;
        uint256 minExecutionWindow = orderPayload.createdAt + uint256(orderPayload.minExecutionTimeInterval) * iteration;
        uint256 maxExecutionWindow = orderPayload.createdAt + uint256(orderPayload.maxExecutionTimeInterval) * iteration;

        if (block.timestamp < minExecutionWindow || block.timestamp > maxExecutionWindow) {
            revert OutsideExecutionWindow();
        }

        recurringExecutedCount[orderHash] = executedCount + 1;

        return true;
    }
}
