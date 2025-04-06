export function stringifyBigInts(obj: any): any {
    if (typeof obj === 'bigint') {
      return obj.toString();
    } else if (Array.isArray(obj)) {
      return obj.map(stringifyBigInts);
    } else if (typeof obj === 'object' && obj !== null) {
      return Object.fromEntries(
        Object.entries(obj).map(([k, v]) => [k, stringifyBigInts(v)])
      );
    }
    return obj;
  }
  
  export function parseBigInts(obj: any): any {
    if (typeof obj === 'string' && /^\d+$/.test(obj)) {
      try {
        return BigInt(obj);
      } catch {
        return obj;
      }
    } else if (Array.isArray(obj)) {
      return obj.map(parseBigInts);
    } else if (typeof obj === 'object' && obj !== null) {
      return Object.fromEntries(
        Object.entries(obj).map(([k, v]) => [k, parseBigInts(v)])
      );
    }
    return obj;
  }
  