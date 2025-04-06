import { NextRequest, NextResponse } from "next/server";
import { PartiallyBuiltOrder } from "../getInstantOrder/types";
import { publishOrder } from "./process"; 

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    if (!body || !body.transferPayload?.witness) {
      return NextResponse.json({ error: "Invalid payload or missing witness" }, { status: 400 });
    }

    const parsedOrder: PartiallyBuiltOrder = body;

    await publishOrder(parsedOrder);

    return NextResponse.json({ success: true }, { status: 200 });
  } catch (error) {
    console.error("Failed to publish order:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}