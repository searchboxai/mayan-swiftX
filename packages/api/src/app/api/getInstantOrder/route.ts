import { NextRequest, NextResponse } from "next/server";
import { integratedChains } from "../getIntegratedChains/process";
import {createOrder} from './process'
import { PartiallyBuiltOrder } from "./types";

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
    
        let error = { message: "", isError: false, code: 400 };
        
        if (!amount) error = { message: "Missing required parameter: amount", isError: true, code: 400 };
        else if (!tokenIn) error = { message: "Missing required parameter: tokenIn", isError: true, code: 400 };
        else if (!tokenOut) error = { message: "Missing required parameter: tokenOut", isError: true, code: 400 };
        else if (!sourceChain) error = { message: "Missing required parameter: sourceChain", isError: true, code: 400 };
        else if (!destChain) error = { message: "Missing required parameter: destChain", isError: true, code: 400 };
        else if (!destAddr) error = { message: "Missing required parameter: destAddr", isError: true, code: 400 };
        else if (!owner) error = { message: "Missing required parameter: owner", isError: true, code: 400 };
        
        if (error.isError) {
            return NextResponse.json({ error: error.message }, { status: error.code });
        }
    
        const order = await createOrder({ amount: amount as string, tokenIn: tokenIn as string, tokenOut: tokenOut as string, destAddr: destAddr as string, sourceChain: sourceChain as string, destChain: destChain as string, owner: owner as string})

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


// curl "https://mayan-swift-x.vercel.app/api/getInstantOrder?amount=2000000&tokenIn=0x833589fcd6edb6e08f4c7c32d4f71b54bda02913&tokenOut=BUYHeMJ668Sc9zH7mKUhSFDQU4oCkeFrkFsSmUjXpump&sourceChain=base&destChain=solana&destAddr=8fFsLKGv5sizL97mjtrVvPu9trQAHZx5HBeLGzLVAt2o&owner=0x1F5781Fce9Ee70eC54047A219c9F128972582eB3"


export function isError(response: PartiallyBuiltOrder | { message: string, isError: boolean, code: number }): 
    response is { message: string, isError: boolean, code: number } {
    return 'isError' in response;
}



//  curl "https://mayan-swift-x.vercel.app/api/getInstantOrder?amount=2000000&tokenIn=0x833589fcd6edb6e08f4c7c32d4f71b54bda02913&tokenOut=BUYHeMJ668Sc9zH7mKUhSFDQU4oCkeFrkFsSmUjXpump&sourceChain=base&destChain=solana&destAddr=8fFsLKGv5sizL97mjtrVvPu9trQAHZx5HBeLGzLVAt2o&owner=0x1F5781Fce9Ee70eC54047A219c9F128972582eB3"

