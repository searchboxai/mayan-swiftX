import {HermesClient} from "@pythnetwork/hermes-client"

const conn = new HermesClient("https://hermes.pyth.network", {});

(async () => {
    // const priceFeeds = await conn.getPriceFeeds({
    //     query: "weth",
    //     assetType: "crypto",
    //   });
    //   console.log(priceFeeds);
    // 9d4294bbcd1174d6f2003ec365831e64cc31d9f6f15a2b85399db8d5000960f6

    const priceUpdates = await conn.getLatestPriceUpdates(["0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace"]);
console.log(priceUpdates);
})()