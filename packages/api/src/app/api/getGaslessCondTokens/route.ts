import {base} from "../getGaslessLimitTokens/route"
import { NextRequest } from "next/server";

export async function GET(request: NextRequest) {
    return base(request); 
}