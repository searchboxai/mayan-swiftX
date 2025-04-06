import { NextRequest } from "next/server";
import { base } from "./process";


export async function GET(request: NextRequest) {
    return base(request);
}

// curl https://mayan-swift-x.vercel.app/api/getGaslessLimitTokens?chain=base


