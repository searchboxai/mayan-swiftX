import { NextRequest, NextResponse } from "next/server";
import { removeOrder } from "./process"; 

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    if (!body || !body.transferPayload?.witness) {
      return NextResponse.json({ error: "Invalid payload or missing witness" }, { status: 400 });
    }

    await removeOrder(body.transferPayload?.witness);

    return NextResponse.json({ success: true }, { status: 200 });
  } catch (error) {
    console.error("Failed to publish order:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}