import { NextRequest, NextResponse } from "next/server";
import { createOrder } from "./process";
import { isError } from "../getInstantOrder/route";
import { integratedChains } from "../getIntegratedChains/process";

export async function GET(request: NextRequest) {
    try {
        const searchParams = request.nextUrl.searchParams;
        const amount = searchParams.get("amount");
        const tokenIn = searchParams.get("tokenIn");
        const tokenOut = searchParams.get("tokenOut");
        const sourceChain = searchParams.get("sourceChain")?.toLowerCase();
        const destChain = searchParams.get("destChain")?.toLowerCase();
        const destAddr = searchParams.get("destAddr")
        const owner = searchParams.get("owner");
        const minExecutionPrice = searchParams.get("minExecutionPrice");
        const maxExecutionPrice = searchParams.get("maxExecutionPrice");
        const minExecutionTime = searchParams.get("minExecutionTime");
        const maxExecutionTime = searchParams.get("maxExecutionTime");
        const oracleFeedId = searchParams.get("oracleFeedId");
        const customOrderType = searchParams.get("customOrderType");

        let error = { message: "", isError: false, code: 400 };

        if (!amount) error = { message: "Missing required parameter: amount", isError: true, code: 400 };
        else if (!tokenIn) error = { message: "Missing required parameter: tokenIn", isError: true, code: 400 };
        else if (!tokenOut) error = { message: "Missing required parameter: tokenOut", isError: true, code: 400 };
        else if (!sourceChain) error = { message: "Missing required parameter: sourceChain", isError: true, code: 400 };
        else if (!destChain) error = { message: "Missing required parameter: destChain", isError: true, code: 400 };
        else if (!destAddr) error = { message: "Missing required parameter: destAddr", isError: true, code: 400 };
        else if (!owner) error = { message: "Missing required parameter: owner", isError: true, code: 400 };
        else if (!minExecutionPrice) error = { message: "Missing required parameter: minExecutionPrice", isError: true, code: 400 };
        else if (!maxExecutionPrice) error = { message: "Missing required parameter: maxExecutionPrice", isError: true, code: 400 };
        else if (!minExecutionTime) error = { message: "Missing required parameter: minExecutionTime", isError: true, code: 400 };
        else if (!maxExecutionTime) error = { message: "Missing required parameter: maxExecutionTime", isError: true, code: 400 };
        else if (!oracleFeedId) error = { message: "Missing required parameter: oracleFeedId", isError: true, code: 400 };
        else if (!customOrderType) error = { message: "Missing required parameter: customOrderType", isError: true, code: 400 };

        if (error.isError) {
            return NextResponse.json({ error: error.message }, { status: error.code });
        }

        const order = await createOrder({ 
            amount: amount as string,
            tokenIn: tokenIn as string, 
            tokenOut: tokenOut as string, 
            destAddr: destAddr as string, 
            sourceChain: sourceChain as string, 
            destChain: destChain as string,
            owner: owner as string,
            minExecutionPrice: minExecutionPrice as string,
            maxExecutionPrice: maxExecutionPrice as string,
            minExecutionTime: minExecutionTime as string,
            maxExecutionTime: maxExecutionTime as string,
            oracleFeedId: oracleFeedId as `0x${string}`,
            customOrderType: customOrderType as string
        })

        if (isError(order)) {
            console.error('Error:', order.message);
            return NextResponse.json({ error: 'internal server error' }, { status: order.code });
        }

        if (!integratedChains[sourceChain as string]?.isIntegratedChain) {
            error = { message: "Source chain is not integrated", isError: true, code: 400 };
        }
    
        if (error.isError) {
            return NextResponse.json({ error: error.message }, { status: error.code });
        }

        const json = JSON.stringify(order, (_, value) =>
            typeof value === "bigint" ? value.toString() : value
          );

        
        return new Response(json, {
            status: 200,
            headers: { "Content-Type": "application/json" },
        })


    } catch (error) {
        console.error("Error processing GET request:", error);
        return NextResponse.json({ error: "Internal server error" }, { status: 500 });
    }
}




// prices from pyth are 8 decimal places 

//  curl "https://mayan-swift-x.vercel.app/api/getCondOrder?amount=2000000&tokenIn=0x833589fcd6edb6e08f4c7c32d4f71b54bda02913&tokenOut=7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs&sourceChain=base&destChain=solana&destAddr=8fFsLKGv5sizL97mjtrVvPu9trQAHZx5HBeLGzLVAt2o&owner=0x1F5781Fce9Ee70eC54047A219c9F128972582eB3&minExecutionPrice=180000000000&maxExecutionPrice=200000000000&minExecutionTime=1743838979&maxExecutionTime=1743859979&oracleFeedId=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace"



// curl "https://mayan-swift-x.vercel.app/api/getCondOrder?amount=2000000&tokenIn=0x833589fcd6edb6e08f4c7c32d4f71b54bda02913&tokenOut=7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs&sourceChain=base&destChain=solana&destAddr=8fFsLKGv5sizL97mjtrVvPu9trQAHZx5HBeLGzLVAt2o&owner=0x1F5781Fce9Ee70eC54047A219c9F128972582eB3&minExecutionPrice=180000000000&maxExecutionPrice=200000000000&minExecutionTime=1743838979&maxExecutionTime=1743859979&oracleFeedId=0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace"


