import {base} from "../getGaslessLimitTokens/process"
import { NextRequest } from "next/server";

export async function GET(request: NextRequest) {
    return base(request); 
}

// curl https://mayan-swift-x.vercel.app/api/getGaslessCondTokens?chain=base