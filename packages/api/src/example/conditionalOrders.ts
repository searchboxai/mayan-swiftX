
import { PartiallyBuiltOrder } from '@/app/api/getInstantOrder/types';
import { fetchQuote } from '@mayanfinance/swap-sdk'
import { toHex, http, parseUnits, hexToBytes, bytesToHex, encodeAbiParameters, keccak256, concatHex, encodePacked, toBytes, getAddress } from 'viem'
import { sign } from 'viem/accounts';

interface TransferPayload {
    permit: {
        permitted: {
            token: `0x${string}`;
            amount: bigint;
        };
        nonce: bigint;
        deadline: bigint;
    };
    transferDetails: {
        to: `0x${string}`;
        requestedAmount: bigint;
    };
    owner: `0x${string}`;
    witnessTypeString: string;
    signature: `0x${string}`;
    witness: `0x${string}`;
}



async function main() {
    // first check if its possible to get a quote on mayan, for frontends this request is autmatic
    const usdcBaseAddr = '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913'
    const wethSolAddr = '7vfCXTUXx5WJV5JADk17DUJ4ksgau7utNKj4b963voxs'
    const destAddr = '8fFsLKGv5sizL97mjtrVvPu9trQAHZx5HBeLGzLVAt2o'
    const owner = '0x1F5781Fce9Ee70eC54047A219c9F128972582eB3'
    const oracleFeedId = '0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace'
    const currentTime = Math.floor(Date.now() / 1000);
    const minExecutionPrice = 180000000000
    const maxExecutionPrice = 200000000000

    // Create a time window (e.g., 2 hours before and after)
    const minExecutionTime = currentTime + 3200; // 1 hour after
    const maxExecutionTime = currentTime + 14400; // 2 hours after
    const amountIn = 20

    const quotes = await fetchQuote({
        amount: amountIn,
        fromToken: usdcBaseAddr,
        toToken: wethSolAddr,
        fromChain: "base",
        toChain: "solana",
        slippageBps: 300, // means 3%
        gasDrop: 0.04, // optional
        referrer: "YOUR SOLANA WALLET ADDRESS", // optional         
    });

    if (!quotes) {
        console.log("No quotes found");
        return;
    }

    const fetchCondOrder = async () => {
        const params = new URLSearchParams({
            amount: quotes[0].effectiveAmountIn64,
            tokenIn: usdcBaseAddr,
            tokenOut: wethSolAddr,
            sourceChain: 'base',
            destChain: 'solana',
            destAddr: destAddr,
            owner: owner,
            minExecutionPrice: minExecutionPrice.toString(),
            maxExecutionPrice: maxExecutionPrice.toString(),
            minExecutionTime: minExecutionTime.toString(),
            maxExecutionTime: maxExecutionTime.toString(),
            oracleFeedId: oracleFeedId,
            customOrderType: '0'
        });
    
        const response = await fetch(`https://mayan-swift-x.vercel.app/api/getCondOrder?${params.toString()}`);
        const data = await response.json();
        return data;
    };

    try {
        const order = await fetchCondOrder();
        order.transferPayload.signature = await getSignature(order.transferPayload, '0xbde0f5f0d9d7b9fcf1ae53c1f2e6a0c84bde0f5f0d9d7b9fcf1ae53c1f2e6a0c') 
        const partiallyBuiltOrder: PartiallyBuiltOrder = order
// publish order
        await fetch('https://mayan-swift-x.vercel.app/api/publishOrder', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(partiallyBuiltOrder),
          })
            .then(res => res.json())
            .then(data => {
              console.log('Success:', data);
            })
            .catch(err => {
              console.error('Error:', err);
            });
    
    } catch (error) {
        console.error('Error fetching instant order:', error);
    }

    // now we fetch the instant order
    const fetchInstantOrder = async () => {
        const params = new URLSearchParams({
            amount: quotes[0].effectiveAmountIn64,
            tokenIn: usdcBaseAddr,
            tokenOut: wethSolAddr,
            sourceChain: 'base',
            destChain: 'solana',
            destAddr: destAddr,
            owner: owner
        });
    
        const response = await fetch(`https://mayan-swift-x.vercel.app/api/getInstantOrder?${params.toString()}`);
        const data = await response.json();
        return data;
    };
    
    try {
        const order = await fetchInstantOrder();
        order.transferPayload.signature = await getSignature(order.transferPayload, '0xbde0f5f0d9d7b9fcf1ae53c1f2e6a0c84bde0f5f0d9d7b9fcf1ae53c1f2e6a0c') 
        const partiallyBuiltOrder: PartiallyBuiltOrder = order
        // publish order
        await fetch('https://mayan-swift-x.vercel.app/api/publishOrder', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(partiallyBuiltOrder),
          })
            .then(res => res.json())
            .then(data => {
              console.log('Success:', data);
            })
            .catch(err => {
              console.error('Error:', err);
            });
          
    } catch (error) {
        console.error('Error fetching instant order:', error);
    }
}

async function getSignature(transferPayload: TransferPayload, privateKey: `0x${string}`) {
      const mayanSwiftX = "0x5D9C504b3F02611912Af20ED39E60C539621E678";
      let TOKEN_PERMISSIONS_TYPEHASH = keccak256(toBytes("TokenPermissions(address token,uint256 amount)"));

      const tokenPermissions = keccak256(
        encodeAbiParameters(
          [
            { name: "typeHash", type: "bytes32" },
            { name: "token", type: "address" },
            { name: "amount", type: "uint256" },
          ],
          [TOKEN_PERMISSIONS_TYPEHASH, transferPayload.permit.permitted.token, transferPayload.permit.permitted.amount]
        )
      );

    let WITNESS_TYPEHASH = keccak256(
        toBytes("PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,OrderPayload witness)OrderPayload(uint256 amountIn,uint256 createdAt,uint256 nonce,bytes32 oracleFeedId,int64 minExecutionPrice,int64 maxExecutionPrice,uint64 minExecutionTime,uint64 maxExecutionTime,uint64 minExecutionTimeInterval,uint64 maxExecutionTimeInterval,address tokenIn,uint8 noOfOrders,uint8 customOrderType,OrderParams orderParams)OrderParams(bytes32 trader,bytes32 tokenOut,uint64 minAmountOut,uint64 gasDrop,uint64 cancelFee,uint64 refundFee,uint64 deadline,bytes32 destAddr,uint16 destChainId,bytes32 referrerAddr,uint8 referrerBps,uint8 auctionMode,bytes32 random)TokenPermissions(address token,uint256 amount)")
    );
    const dataHash = keccak256(
        encodeAbiParameters(
          [
            { name: "typehash", type: "bytes32" },
            { name: "tokenPermissions", type: "bytes32" },
            { name: "mayanSwiftX", type: "address" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" },
            { name: "witness", type: "bytes32" },
          ],
          [
            WITNESS_TYPEHASH,
            tokenPermissions,
            mayanSwiftX,
            transferPayload.permit.nonce,
            transferPayload.permit.deadline,
            transferPayload.witness,
          ]
        )
      );
    
    const msgHash = keccak256(
        encodePacked(
          ["bytes2", "bytes32", "bytes32"],
          ["0x1901", "0x3b6f35e4fce979ef8eac3bcdc8c3fc38fe7911bb0c69c8fe72bf1fd1a17e6f07", dataHash]
        )
      );

      const signature = await sign({
        hash: msgHash,
        privateKey,
      });

      let v: bigint;
      if (signature.v !== undefined) {
        v = signature.v;
      } else if (signature.yParity !== undefined) {
        // Compute 'v' based on 'yParity'
        // Assuming chainId is known and is an integer
        const chainId = 1; // Replace with your actual chain ID
        v = BigInt(signature.yParity) + BigInt(27) + BigInt(chainId) * BigInt(2);
      } else {
        throw new Error("Both 'v' and 'yParity' are undefined in the signature.");
      }
      
      return concatHex([signature.r, signature.s, toHex(v)]);
}
// npx tsx ./packages/api/src/example/conditionalOrders.ts

main();
