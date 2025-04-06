import { PartiallyBuiltOrder } from "../getInstantOrder/types"
import { addOrder } from "../../../db/actions"

export async function publishOrder(partiallyBuiltOrder: PartiallyBuiltOrder) {
    await addOrder(partiallyBuiltOrder, partiallyBuiltOrder.transferPayload.witness);
}