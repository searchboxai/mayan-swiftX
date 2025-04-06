import { ByteArray } from "viem";

export interface OrderPayload {
    amountIn: bigint;
    createdAt: bigint;
    nonce: bigint;
    oracleFeedId: `0x${string}`
    minExecutionPrice: bigint;
    maxExecutionPrice: bigint;
    minExecutionTime: bigint;
    maxExecutionTime: bigint;
    minExecutionTimeInterval: bigint;
    maxExecutionTimeInterval: bigint;
    tokenIn: `0x${string}`;
    noOfOrders: number;
    customOrderType: number;
    orderParams: OrderParams;
}
    
export interface OrderParams {
    trader: `0x${string}`;
    tokenOut: `0x${string}`;
    minAmountOut: bigint;
    gasDrop: bigint;
    cancelFee: bigint;
    refundFee: bigint;
    deadline: bigint;
    destAddr: `0x${string}`;
    destChainId: number;
    referrerAddr: `0x${string}`;
    referrerBps: number;
    auctionMode: number;
    random: `0x${string}`;
}     

export interface TransferPayload {
    permit: {
        permitted: {
            token: string;
            amount: bigint;
        };
        nonce: bigint;
        deadline: bigint;
    };
    transferDetails: {
        to: string;
        requestedAmount: bigint;
    };
    owner: string;
    witnessTypeString: string;
    signature: string;
    witness: string;
}

export enum OrderType {
    Pending = 0,
    InProgress = 1,
    Complete = 2,
    Cancelled = 3
}

export interface ExecutionPayload {
    encodedOrder: {
        trader: string;
        minExecutionPrice: bigint;
        maxExecutionPrice: bigint;
        minExecutionTime: bigint;
        maxExecutionTime: bigint;
        status: OrderType;
    }
}

export type PartiallyBuiltOrder = {
    orderPayload: OrderPayload;
    transferPayload: TransferPayload;
}

