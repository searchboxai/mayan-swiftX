import {createPublicClient, http, keccak256, PublicClient, toBytes} from 'viem'
// import { base } from '../getGaslessTokens/process'
import { base as baseChain, optimism } from 'viem/chains'
import 'dotenv/config'


export const mayanSwiftX = '0x5D9C504b3F02611912Af20ED39E60C539621E678'

export const nonceFinderPermit2 = '0x09E158963a82834a6387bcedEbC0C9d245C4f74c'

export const executoor = '0x330cA32b71b81Ea2b1D3a5C391C5cFB6520E0A10'

export const witnessTypeHash = keccak256(
    toBytes("PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,OrderPayload witness)OrderPayload(uint256 amountIn,uint256 createdAt,uint256 nonce,bytes32 oracleFeedId,int64 minExecutionPrice,int64 maxExecutionPrice,uint64 minExecutionTime,uint64 maxExecutionTime,uint64 minExecutionTimeInterval,uint64 maxExecutionTimeInterval,address tokenIn,uint8 noOfOrders,uint8 customOrderType,OrderParams orderParams)OrderParams(bytes32 trader,bytes32 tokenOut,uint64 minAmountOut,uint64 gasDrop,uint64 cancelFee,uint64 refundFee,uint64 deadline,bytes32 destAddr,uint16 destChainId,bytes32 referrerAddr,uint8 referrerBps,uint8 auctionMode,bytes32 random)TokenPermissions(address token,uint256 amount)")
)

export const witnessTypeString = "OrderPayload witness)OrderPayload(uint256 amountIn,uint256 createdAt,uint256 nonce,bytes32 oracleFeedId,int64 minExecutionPrice,int64 maxExecutionPrice,uint64 minExecutionTime,uint64 maxExecutionTime,uint64 minExecutionTimeInterval,uint64 maxExecutionTimeInterval,address tokenIn,uint8 noOfOrders,uint8 customOrderType,OrderParams orderParams)OrderParams(bytes32 trader,bytes32 tokenOut,uint64 minAmountOut,uint64 gasDrop,uint64 cancelFee,uint64 refundFee,uint64 deadline,bytes32 destAddr,uint16 destChainId,bytes32 referrerAddr,uint8 referrerBps,uint8 auctionMode,bytes32 random)TokenPermissions(address token,uint256 amount)"

export const getChains = {
    base: baseChain,
    optimism: optimism
}

export const getReferrer = {
    base: "0x330cA32b71b81Ea2b1D3a5C391C5cFB6520E0A10",
    optimism: "0x330cA32b71b81Ea2b1D3a5C391C5cFB6520E0A10", 
    solana: '8fFsLKGv5sizL97mjtrVvPu9trQAHZx5HBeLGzLVAt2o'
}

export const getAlchemyUrl = {
    base: process.env.ALCHEMY_BASE,
    optimism: process.env.ALCHEMY_OP,
    
}

export const mayanSwiftXAbi = [
    {
        name: "execute",
        type: "function",
        stateMutability: "payable",
        inputs: [
            {
                name: "transferPayload",
                type: "tuple",
                internalType: "struct IMayanSwiftX.TransferPayload",
                components: [
                    {
                        name: "permit",
                        type: "tuple",
                        internalType: "struct ISignatureTransfer.PermitTransferFrom",
                        components: [
                            {
                                name: "permitted",
                                type: "tuple",
                                internalType: "struct ISignatureTransfer.TokenPermissions",
                                components: [
                                    { name: "token", type: "address", internalType: "address" },
                                    { name: "amount", type: "uint256", internalType: "uint256" }
                                ]
                            },
                            { name: "nonce", type: "uint256", internalType: "uint256" },
                            { name: "deadline", type: "uint256", internalType: "uint256" }
                        ]
                    },
                    {
                        name: "transferDetails",
                        type: "tuple",
                        internalType: "struct ISignatureTransfer.SignatureTransferDetails",
                        components: [
                            { name: "to", type: "address", internalType: "address" },
                            { name: "requestedAmount", type: "uint256", internalType: "uint256" }
                        ]
                    },
                    { name: "owner", type: "address", internalType: "address" },
                    { name: "witness", type: "bytes32", internalType: "bytes32" },
                    { name: "witnessTypeString", type: "string", internalType: "string" },
                    { name: "signature", type: "bytes", internalType: "bytes" }
                ]
            },
            {
                name: "orderPayload",
                type: "tuple",
                internalType: "struct IMayanSwiftX.OrderPayload",
                components: [
                    { name: "amountIn", type: "uint256", internalType: "uint256" },
                    { name: "createdAt", type: "uint256", internalType: "uint256" },
                    { name: "nonce", type: "uint256", internalType: "uint256" },
                    { name: "oracleFeedId", type: "bytes32", internalType: "bytes32" },
                    { name: "minExecutionPrice", type: "int64", internalType: "int64" },
                    { name: "maxExecutionPrice", type: "int64", internalType: "int64" },
                    { name: "minExecutionTime", type: "uint64", internalType: "uint64" },
                    { name: "maxExecutionTime", type: "uint64", internalType: "uint64" },
                    { name: "minExecutionTimeInterval", type: "uint64", internalType: "uint64" },
                    { name: "maxExecutionTimeInterval", type: "uint64", internalType: "uint64" },
                    { name: "tokenIn", type: "address", internalType: "address" },
                    { name: "noOfOrders", type: "uint8", internalType: "uint8" },
                    { name: "customOrderType", type: "uint8", internalType: "enum IMayanSwiftX.CustomOrderType" },
                    {
                        name: "orderParams",
                        type: "tuple",
                        internalType: "struct IMayanSwift.OrderParams",
                        components: [
                            { name: "trader", type: "bytes32", internalType: "bytes32" },
                            { name: "tokenOut", type: "bytes32", internalType: "bytes32" },
                            { name: "minAmountOut", type: "uint64", internalType: "uint64" },
                            { name: "gasDrop", type: "uint64", internalType: "uint64" },
                            { name: "cancelFee", type: "uint64", internalType: "uint64" },
                            { name: "refundFee", type: "uint64", internalType: "uint64" },
                            { name: "deadline", type: "uint64", internalType: "uint64" },
                            { name: "destAddr", type: "bytes32", internalType: "bytes32" },
                            { name: "destChainId", type: "uint16", internalType: "uint16" },
                            { name: "referrerAddr", type: "bytes32", internalType: "bytes32" },
                            { name: "referrerBps", type: "uint8", internalType: "uint8" },
                            { name: "auctionMode", type: "uint8", internalType: "uint8" },
                            { name: "random", type: "bytes32", internalType: "bytes32" }
                        ]
                    }
                ]
            },
            { name: "updateData", type: "bytes[]", internalType: "bytes[]" }
        ],
        outputs: []
    }
]

export const nonceFinderPermit2Abi = [
    {
        name: 'nextNonce',
        type: 'function',
        stateMutability: 'view',
        inputs: [{ name: 'owner', type: 'address' }],
        outputs: [{ type: 'uint256' }]
    },
]

function isValidChain(chain: string): chain is keyof typeof getChains {
    return chain in getChains;
}

export async function getPublicClient(chainStr: string): Promise<PublicClient | undefined> {
    if (!isValidChain(chainStr)) return undefined
    return createPublicClient(
        {
            chain: getChains[chainStr as keyof typeof getChains],
            transport: http(getAlchemyUrl[chainStr as keyof typeof getAlchemyUrl])
        }
    ) as PublicClient;
}
          
export async function getLatestBlockTimestamp(pubClient: PublicClient): Promise<bigint | undefined> {
    const block = await pubClient.getBlock(); 
    return block.timestamp;
}
