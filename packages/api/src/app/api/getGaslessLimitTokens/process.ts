import { getTokens } from "../getGaslessTokens/process"
import { integratedChains } from "../getIntegratedChains/process";
import { NextRequest } from "next/server";


async function compareAgainstPyth(tokenChain: string) {
    const tokens = await getTokens(tokenChain)
    let limitTokens: string[] = [];

    for (let i = 0; i < tokens.length; i++) {
        let tokenSymbol = tokens[i].symbol.toLowerCase()
        const url = `https://hermes.pyth.network/v2/price_feeds?query=${tokenSymbol}&asset_type=crypto`
        const response = await fetch(url, {
            headers: {
                'Accept': 'application/json' 
            }
        })

        const pythData = await response.json()

        for (let i = 0; i < pythData.length; i++) {
            if (tokenSymbol == pythData[i].attributes.base.toLowerCase()) {
                limitTokens.push(tokenSymbol)
                break
            } 
        }
    }
     
    return limitTokens
}

export async function base(request: NextRequest) {
    const searchParams = request.nextUrl.searchParams;
    const chain = searchParams.get("chain")?.toLowerCase(); 

    if (chain && integratedChains[chain]?.isIntegratedChain) {
        try {
            const limitTokens = await compareAgainstPyth(chain)
            return new Response(JSON.stringify(limitTokens), {
                status: 200,
                headers: { "Content-Type": "application/json" },
            });
        } catch (error) {
            const errorMessage = (error as Error).message || "Unknown error occurred";
            return new Response(JSON.stringify({ error: errorMessage }), {
                status: 500,
                headers: { "Content-Type": "application/json" },
            });
        }
    } else {
        return new Response(JSON.stringify({ error: "Chain not found" }), {
            status: 404,
            headers: { "Content-Type": "application/json" },
        });
    }
}
