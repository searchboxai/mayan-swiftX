import { doc, setDoc, getDoc, deleteDoc, collection, getDocs } from "firebase/firestore";
import { stringifyBigInts, parseBigInts } from "./helper";
import { db } from "./db";
import { PartiallyBuiltOrder } from "../app/api/getInstantOrder/types";

export async function addOrder(order: PartiallyBuiltOrder, orderId: string) {
  const orderToSave = stringifyBigInts(order);
  const docRef = doc(db, "orders", orderId);
  await setDoc(docRef, orderToSave);
}

export async function getOrder(orderId: string): Promise<PartiallyBuiltOrder | null> {
  const docRef = doc(db, "orders", orderId);
  const snap = await getDoc(docRef);
  if (!snap.exists()) return null;

  const data = snap.data();
  return parseBigInts(data) as PartiallyBuiltOrder;
}

export async function getOrders(): Promise<PartiallyBuiltOrder[]> {
  const ordersCol = collection(db, "orders");
  const snapshot = await getDocs(ordersCol);
  const orders: PartiallyBuiltOrder[] = [];

  snapshot.forEach((docSnapshot) => {
    const data = docSnapshot.data();
    orders.push(parseBigInts(data) as PartiallyBuiltOrder);
  });

  return orders;
}
export async function deleteOrder(orderId: string): Promise<void> {
  const docRef = doc(db, "orders", orderId);
  await deleteDoc(docRef);
}
