// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "permit2/interfaces/ISignatureTransfer.sol";
import "permit2/interfaces/IAllowanceTransfer.sol";
import "./IMayanSwift.sol";

interface IMayanSwiftX {
    error WitnessMismatch();
    error OutsideExecutionWindow();
    error OutsideExecutionPrice();
    error InvalidOrderNonce();
    error FailedSignatureVerification();
    error CancelledOrder();
    error AllOrdersExecuted();

    event OrderCancelled(bytes32 indexed witness, address indexed owner);

    struct TransferPayload {
        ISignatureTransfer.PermitTransferFrom permit;
        ISignatureTransfer.SignatureTransferDetails transferDetails;
        address owner;
        bytes32 witness;
        string witnessTypeString;
        bytes signature;
    }

    struct OrderPayload {
        uint256 amountIn;
        uint256 createdAt;
        uint256 nonce;
        bytes32 oracleFeedId;
        int64 minExecutionPrice;
        int64 maxExecutionPrice;
        uint64 minExecutionTime;
        uint64 maxExecutionTime; // orders have a 21 days max execution window
        uint64 minExecutionTimeInterval;
        uint64 maxExecutionTimeInterval;
        address tokenIn;
        uint8 noOfOrders;
        CustomOrderType customOrderType;
        IMayanSwift.OrderParams orderParams;
    }

    struct AllowancePayload {
        address owner;
        bytes32 orderHash;
        address tokenIn;
        bytes orderPayloadSignature; // sig(address(this) ++ chainId ++ orderPayload)
        bytes allowancePayloadSig;
        IAllowanceTransfer.PermitSingle permitSingle;
    }

    enum CustomOrderType {
        PriceOrder,
        TimeOrder,
        RecurringOrder
    }
}
