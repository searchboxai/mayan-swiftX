import { OrderPayload, PartiallyBuiltOrder, } from "../getInstantOrder/types";
import { getPublicClient, nonceFinderPermit2Abi, nonceFinderPermit2, getLatestBlockTimestamp } from "../getInstantOrder/const";
import { getWitness, startBuildingTransferPayload, fetchQuote, fillOrderPayloadwithQoute } from "../getInstantOrder/process";
import { ChainName} from '@mayanfinance/swap-sdk';
import { Address, getAddress, parseUnits, PublicClient } from "viem";

function startBuildingOrderPayload(
    customOrderType: number,
    createdAt: bigint, 
    amountIn: bigint,
    nonce: bigint, 
    tokenIn: Address,
    minExecutionPrice: bigint,
    maxExecutionPrice: bigint,
    minExecutionTime: bigint,
    maxExecutionTime: bigint,
    oracleFeedId: `0x${string}`
): OrderPayload{    
    let orderPayload: OrderPayload = {} as OrderPayload
    orderPayload.amountIn = amountIn
    orderPayload.createdAt = createdAt
    orderPayload.nonce = nonce
    orderPayload.minExecutionPrice = minExecutionPrice
    orderPayload.maxExecutionPrice = maxExecutionPrice
    orderPayload.minExecutionTime = minExecutionTime 
    orderPayload.maxExecutionTime = maxExecutionTime
    orderPayload.minExecutionTimeInterval = 0n
    orderPayload.maxExecutionTimeInterval = 0n
    orderPayload.tokenIn = tokenIn
    orderPayload.noOfOrders = 0
    orderPayload.customOrderType = customOrderType
    orderPayload.oracleFeedId = oracleFeedId
    return orderPayload
}

export async function createOrder(
    params: {
        amount: string;
        tokenIn: string;
        tokenOut: string;
        destAddr: string;
        sourceChain: string;
        destChain: string;
        owner: string;
        minExecutionPrice: string,
        maxExecutionPrice: string,
        minExecutionTime: string,
        maxExecutionTime: string,
        oracleFeedId: `0x${string}`,
        customOrderType: string
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

    let orderPayload: OrderPayload = startBuildingOrderPayload(
        Number(params.customOrderType),
        blocktimestamp as bigint,
        amountIn,
        nextNonce as bigint,
        getAddress(params.tokenIn),
        parseUnits(params.minExecutionPrice , 0),
        parseUnits(params.maxExecutionPrice , 0),
        parseUnits(params.minExecutionTime , 0),
        parseUnits(params.maxExecutionTime , 0),
        fetchedQuote.toToken?.pythUsdPriceId as `0x${string}`
    )

    const updatedOrderPayload = fillOrderPayloadwithQoute(orderPayload, fetchedQuote, params.owner, params.destAddr)

    if (!updatedOrderPayload) return { message: "Undefined responce from updating orderpayload with quote: undefined", isError: true, code: 400 };

    orderPayload = updatedOrderPayload as OrderPayload

    const witness = getWitness(orderPayload)

    const transferPayload = startBuildingTransferPayload(orderPayload, witness)

    return {orderPayload: orderPayload, transferPayload: transferPayload}
}