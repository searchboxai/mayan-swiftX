
import {ExecutionPayload, OrderPayload, TransferPayload, OrderParams, PartiallyBuiltOrder} from "./types"

import { mayanSwiftX, nonceFinderPermit2, getPublicClient, nonceFinderPermit2Abi, getReferrer, getLatestBlockTimestamp, witnessTypeString } from "./const";
import { fetchQuote as mayanFetchQuotes, Quote, ChainName } from '@mayanfinance/swap-sdk';

import { Address, PublicClient, getAddress, parseUnits, encodeAbiParameters, keccak256 } from "viem";
import { UniversalAddress } from '@wormhole-foundation/sdk';

interface ExtendedToToken {
    pythUsdPriceId: string;
}

// Create a new type that combines the original Quote with our extension
type ExtendedQuote = Quote & {
    toToken: Quote['toToken'] & ExtendedToToken;
}
const platformAddressFormatEntries = {
    'Evm': 'hex',
    'Solana': 'base58',
    'Cosmwasm': 'bech32',
    'Algorand': 'algorandAppId',
    'Sui': 'hex',
    'Aptos': 'hex',
    'Near': 'sha256'
} as const;

export async function createOrder(
    params: {
        amount: string;
        tokenIn: string;
        tokenOut: string;
        destAddr: string;
        sourceChain: string;
        destChain: string;
        owner: string;
    }      
): Promise<PartiallyBuiltOrder | { message: string, isError: boolean, code: 400 }>  {
    const pClient = await getPublicClient(params.sourceChain)

    if (!pClient) return { message: "Undefined responce from getting view public client: undefined", isError: true, code: 400 };

    const nextNonce = await pClient?.readContract({
        address: nonceFinderPermit2,
        abi: nonceFinderPermit2Abi, 
        functionName: 'nextNonce',
        args: [getAddress(params.owner)]
    })

    if (nextNonce == undefined) return { message: "Undefined responce from getting users unused nonce: undefined", isError: true, code: 400 };

    const fetchedQuote = await fetchQuote(
        params.sourceChain as ChainName, 
        params.destChain as ChainName, 
        params.tokenIn, 
        params.tokenOut,
        params.amount
    )

    if (!fetchedQuote) return { message: "Undefined responce from getting an order quote from mayan: undefined", isError: true, code: 400 };

    const blocktimestamp = await getLatestBlockTimestamp(pClient as PublicClient)

    if (blocktimestamp == undefined) return { message: "Undefined responce from getting the latest block.timstamp: undefined", isError: true, code: 400 };

    const amountIn = BigInt(params.amount)

    let orderPayload: OrderPayload = startBuildingOrderPayload(blocktimestamp as bigint, amountIn, nextNonce as bigint, getAddress(params.tokenIn))

    const updatedOrderPayload = fillOrderPayloadwithQoute(orderPayload, fetchedQuote, params.owner, params.destAddr)
    
    if (!updatedOrderPayload) return { message: "Undefined responce from updating orderpayload with quote: undefined", isError: true, code: 400 };

    orderPayload = updatedOrderPayload as OrderPayload

    const witness = getWitness(orderPayload)

    const transferPayload = startBuildingTransferPayload(orderPayload, witness)

    return {orderPayload: orderPayload, transferPayload: transferPayload}
}


export async function fetchQuote(
    fromChain: ChainName, 
    toChain: ChainName, 
    fromToken: string, 
    toToken: string, 
    amount: string
): Promise<ExtendedQuote> {
    const quotes = await mayanFetchQuotes({
        amountIn64: amount, 
        fromToken: fromToken,
        toToken: toToken,
        fromChain: fromChain,
        toChain: toChain, 
        slippageBps: 'auto',
        referrer: getReferrer[toChain as keyof typeof getReferrer]
    });
    return quotes[0]! as ExtendedQuote;
}

function startBuildingOrderPayload(
    createdAt: bigint, 
    amountIn: bigint,
    nonce: bigint, 
    tokenIn: Address
): OrderPayload {
    let orderPayload: OrderPayload = {} as OrderPayload
    orderPayload.amountIn = amountIn
    orderPayload.createdAt = createdAt
    orderPayload.nonce = nonce
    orderPayload.minExecutionPrice = BigInt(0)
    orderPayload.maxExecutionPrice = BigInt(0)
    orderPayload.minExecutionTime = createdAt 
    orderPayload.maxExecutionTime = createdAt + 600n
    orderPayload.minExecutionTimeInterval = 0n
    orderPayload.maxExecutionTimeInterval = 0n
    orderPayload.tokenIn = tokenIn
    orderPayload.noOfOrders = 0
    orderPayload.customOrderType = 1
    orderPayload.oracleFeedId = hexToBytes32("0x00")
    return orderPayload
}

export function startBuildingTransferPayload(
    orderPayload_: OrderPayload,
    witness: `0x${string}`
): TransferPayload {
    let transferPayload: TransferPayload = {} as TransferPayload

    transferPayload.permit = {
        permitted: {
            token: orderPayload_.tokenIn,
            amount: orderPayload_.amountIn,
        },
        nonce: orderPayload_.nonce,
        deadline: orderPayload_.maxExecutionTime,
    }

    transferPayload.transferDetails = {
        to: mayanSwiftX, // => dynamic for solana
        requestedAmount: orderPayload_.amountIn,
    }

    transferPayload.owner = orderPayload_.orderParams.trader  
    transferPayload.witnessTypeString = witnessTypeString
    transferPayload.witness = witness

    return transferPayload
}

export function fillOrderPayloadwithQoute(
    orderpayload_: OrderPayload, 
    quote_: Quote, 
    trader: string, 
    destAddr: string
): OrderPayload | undefined {
    const destNativeName = firstLetterCaps(quote_.toChain.toString()) as string

    const selectedPlatform = destNativeName == 'Solana' ? platformAddressFormatEntries['Solana'] : platformAddressFormatEntries['Evm']

    const tokenOut = new UniversalAddress(quote_.toToken.contract?.toString() as string, selectedPlatform);
    
    if (!tokenOut) return undefined

    const destOut = new UniversalAddress(destAddr as string, selectedPlatform);

    if (!destOut) return undefined

    const referrer = new UniversalAddress(getReferrer.solana, selectedPlatform);

    if (!referrer) return undefined

    const universalAddressTokenOut = tokenOut.toString();
    const universalAddressDestOut = destOut.toString();
    const universalAddressReferrer = referrer.toString();

    orderpayload_.orderParams  = {
        trader: addressToBytes32(trader),
        tokenOut: universalAddressTokenOut,
        gasDrop: parseUnits(quote_.gasDrop.toString(), 0),
        cancelFee: parseUnits(quote_.cancelRelayerFee64.toString(), 0), 
        refundFee: parseUnits(quote_.refundRelayerFee64.toString(), 0),
        deadline: BigInt(quote_.deadline64),
        minAmountOut: parseUnits(quote_.minAmountOut.toString(), 0),
        destAddr: universalAddressDestOut, 
        destChainId: quote_.toToken.wChainId,
        referrerAddr: universalAddressReferrer,
        referrerBps: 2,
        auctionMode: quote_.swiftAuctionMode,
        random: hexToBytes32("f2003ec365831e64cc31d9f6f15a2b85399db8d5000960f6")
    } as OrderParams

    return orderpayload_
}

function addressToBytes32(address: string): `0x${string}` {
    return `0x${address.slice(2).padStart(64, '0')}` as `0x${string}`;
}

function firstLetterCaps(word: string): string {
    return word.charAt(0).toUpperCase() + word.slice(1)
}

function hexToBytes32(hex: string): `0x${string}` {
    return `0x${hex.padStart(64, '0')}` as `0x${string}`;
}

export function getWitness(orderPayload_: OrderPayload) {
    const encodedData = encodeAbiParameters(
        [
          { name: 'amountIn', type: 'uint256' },
          { name: 'createdAt', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'oracleFeedId', type: 'bytes32' },
          { name: 'minExecutionPrice', type: 'int64' },
          { name: 'maxExecutionPrice', type: 'int64' },
          { name: 'minExecutionTime', type: 'uint64' },
          { name: 'maxExecutionTime', type: 'uint64' },
          { name: 'minExecutionTimeInterval', type: 'uint64' },
          { name: 'maxExecutionTimeInterval', type: 'uint64' },
          { name: 'tokenIn', type: 'address' },
          { name: 'noOfOrders', type: 'uint8' },
          { name: 'customOrderType', type: 'uint8' },
          { 
            name: 'orderParams', 
            type: 'tuple', 
            components: [
              { name: 'trader', type: 'bytes32' },
              { name: 'tokenOut', type: 'bytes32' },
              { name: 'minAmountOut', type: 'uint64' },
              { name: 'gasDrop', type: 'uint64' },
              { name: 'cancelFee', type: 'uint64' },
              { name: 'refundFee', type: 'uint64' },
              { name: 'deadline', type: 'uint64' },
              { name: 'destAddr', type: 'bytes32' },
              { name: 'destChainId', type: 'uint16' },
              { name: 'referrerAddr', type: 'bytes32' },
              { name: 'referrerBps', type: 'uint8' },
              { name: 'auctionMode', type: 'uint8' },
              { name: 'random', type: 'bytes32' }
            ]
          }
        ], 
        [
            orderPayload_.amountIn,
            orderPayload_.createdAt,
            orderPayload_.nonce,
            orderPayload_.oracleFeedId,
            orderPayload_.minExecutionPrice,
            orderPayload_.maxExecutionPrice,
            orderPayload_.minExecutionTime,
            orderPayload_.maxExecutionTime,
            orderPayload_.minExecutionTimeInterval,
            orderPayload_.maxExecutionTimeInterval,
            orderPayload_.tokenIn,
            orderPayload_.noOfOrders,
            orderPayload_.customOrderType,
            orderPayload_.orderParams,
        ]
    )
    return keccak256(encodedData)
}







