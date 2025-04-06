import { deleteOrder } from "../../../db/actions";

export async function removeOrder(witness: string) {
  await deleteOrder(witness);
}