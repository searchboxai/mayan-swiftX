import { NextRequest } from "next/server";
import {base} from './process'

export async function GET(request: NextRequest) {
    return base(request); 
}