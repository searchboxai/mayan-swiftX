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
