type IntegratedChain = { [key: string]: { isIntegratedChain: boolean; tokenStandard: string } }; 

export const integratedChains: IntegratedChain = {
    "base": {
        isIntegratedChain: true,
        tokenStandard: 'erc20'
    },
    'optimism': {
        isIntegratedChain: true,
        tokenStandard: 'erc20'
    }
}

export async function GET(_request: Request) {
    return new Response(JSON.stringify(integratedChains), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
}