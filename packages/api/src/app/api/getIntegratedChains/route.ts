import { integratedChains } from "./process";

export async function GET(_request: Request) {
    return new Response(JSON.stringify(integratedChains), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
}

// curl https://mayan-swift-x.vercel.app/api/getIntegratedChains