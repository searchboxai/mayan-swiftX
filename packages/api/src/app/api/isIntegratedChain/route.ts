import { NextRequest } from 'next/server';
import { integratedChains } from "../getIntegratedChains/process";
import 'dotenv/config'
    
export async function GET(request: NextRequest) {
    const searchParams = request.nextUrl.searchParams;
    const chain = searchParams.get('chain')?.toLocaleLowerCase(); 

    if (chain && integratedChains[chain].isIntegratedChain) {
        return new Response(JSON.stringify({[chain]: integratedChains[chain].isIntegratedChain}), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        });
    } else {
        return new Response(JSON.stringify({ error: 'Chain not found' }), {
            status: 404,
            headers: { 'Content-Type': 'application/json' }
        });
    }
}


// curl https://mayan-swift-x.vercel.app/api/isIntegratedChain?chain=base
