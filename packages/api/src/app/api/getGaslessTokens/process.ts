import { integratedChains } from "../getIntegratedChains/process";
import { NextRequest } from "next/server";


export async function getTokens(tokenChain: string) {
    const baseUrl = `https://price-api.mayan.finance/v3/tokens?chain=${tokenChain}&nonPortal=`;
    const tokenStandard = integratedChains[tokenChain]?.tokenStandard;
    const isPortal = true;
    let mergedTokens: any[] = [];

    try {
        const response01 = await fetch(`${baseUrl}${isPortal}&standard=${tokenStandard}`);
        if (!response01.ok) {
            throw new Error(`Response status: ${response01.status}`);
        }
        const json01 = await response01.json();
        const tokens01 = json01?.[tokenChain] || [];
        mergedTokens.push(...tokens01);

        const response02 = await fetch(`${baseUrl}${!isPortal}&standard=${tokenStandard}`);
        if (!response02.ok) {
            throw new Error(`Response status: ${response02.status}`);
        }
        const json02 = await response02.json();
        const tokens02 = json02?.[tokenChain] || [];
        mergedTokens.push(...tokens02);

        return mergedTokens;
    } catch (error) {
        console.error("Error fetching tokens:", error);
        throw new Error("Failed to fetch tokens");
    }
}

export async function base(request: NextRequest) {
    const searchParams = request.nextUrl.searchParams;
    const chain = searchParams.get("chain")?.toLowerCase(); 

    if (chain && integratedChains[chain]?.isIntegratedChain) {
        try {
            const gaslessTokens = await getTokens(chain);
            return new Response(JSON.stringify(gaslessTokens), {
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

// curl https://mayan-swift-x.vercel.app/api/getGaslessTokens?chain=base