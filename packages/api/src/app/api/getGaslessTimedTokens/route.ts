import {base} from "../getGaslessTokens/process"
import { NextRequest } from "next/server";

export async function GET(request: NextRequest) {
    return base(request); 
}


// curl https://mayan-swift-x.vercel.app/api/getGaslessTimedTokens?chain=base