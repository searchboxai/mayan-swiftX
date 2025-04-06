// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SignatureChecker.sol";

interface IMayanForwarder {
    function forwardERC20(
        address tokenIn,
        uint256 amountIn,
        SignatureChecker.PermitParams calldata permitParams,
        address mayanProtocol,
        bytes calldata protocolData
    ) external payable;
}
