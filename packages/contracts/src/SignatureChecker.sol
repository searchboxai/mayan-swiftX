// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract SignatureChecker {
    struct PermitParams {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bytes32 constant WITNESS_TYPEHASH = keccak256(
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,OrderPayload witness)OrderPayload(uint256 amountIn,uint256 createdAt,uint256 nonce,bytes32 oracleFeedId,int64 minExecutionPrice,int64 maxExecutionPrice,uint64 minExecutionTime,uint64 maxExecutionTime,uint64 minExecutionTimeInterval,uint64 maxExecutionTimeInterval,address tokenIn,uint8 noOfOrders,uint8 customOrderType,OrderParams orderParams)OrderParams(bytes32 trader,bytes32 tokenOut,uint64 minAmountOut,uint64 gasDrop,uint64 cancelFee,uint64 refundFee,uint64 deadline,bytes32 destAddr,uint16 destChainId,bytes32 referrerAddr,uint8 referrerBps,uint8 auctionMode,bytes32 random)TokenPermissions(address token,uint256 amount)"
    );

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");
}
