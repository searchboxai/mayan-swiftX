// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "permit2/Permit2.sol";
import "permit2/interfaces/ISignatureTransfer.sol";
import "permit2/interfaces/IAllowanceTransfer.sol";
import "src/interfaces/IMayanSwift.sol";
import "src/interfaces/IMayanSwiftX.sol";
import "src/MayanSwiftX.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Test, console} from "forge-std/Test.sol";

contract MayanSwiftXTest is Test {
    MayanSwiftX public mayanSwiftX;
    Permit2 public permit2;
    uint256 public baseFork;
    address public usdcAddress = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public wethAddress = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public permit2Address = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address public mayan = 0xC38e4e6A15593f908255214653d3D947CA1c2338;
    address public pythAddress = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;
    address public usdcWhale = 0x0B0A5886664376F59C351ba3f598C8A8B4D0A6f3;
    address mayanForwader = 0x337685fdaB40D39bd02028545a4FfA7D287cC3E2;
    bytes32 public ethPriceFeedId = 0x9d4294bbcd1174d6f2003ec365831e64cc31d9f6f15a2b85399db8d5000960f6;

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    string constant WITNESS_TYPE_STRING =
        "OrderPayload witness)OrderPayload(uint256 amountIn,uint256 createdAt,uint256 nonce,bytes32 oracleFeedId,int64 minExecutionPrice,int64 maxExecutionPrice,uint64 minExecutionTime,uint64 maxExecutionTime,uint64 minExecutionTimeInterval,uint64 maxExecutionTimeInterval,address tokenIn,uint8 noOfOrders,uint8 customOrderType,OrderParams orderParams)OrderParams(bytes32 trader,bytes32 tokenOut,uint64 minAmountOut,uint64 gasDrop,uint64 cancelFee,uint64 refundFee,uint64 deadline,bytes32 destAddr,uint16 destChainId,bytes32 referrerAddr,uint8 referrerBps,uint8 auctionMode,bytes32 random)TokenPermissions(address token,uint256 amount)";

    bytes32 public constant domainSeperator = 0x3b6f35e4fce979ef8eac3bcdc8c3fc38fe7911bb0c69c8fe72bf1fd1a17e6f07;

    bytes32 constant WITNESS_TYPEHASH = keccak256(
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,OrderPayload witness)OrderPayload(uint256 amountIn,uint256 createdAt,uint256 nonce,bytes32 oracleFeedId,int64 minExecutionPrice,int64 maxExecutionPrice,uint64 minExecutionTime,uint64 maxExecutionTime,uint64 minExecutionTimeInterval,uint64 maxExecutionTimeInterval,address tokenIn,uint8 noOfOrders,uint8 customOrderType,OrderParams orderParams)OrderParams(bytes32 trader,bytes32 tokenOut,uint64 minAmountOut,uint64 gasDrop,uint64 cancelFee,uint64 refundFee,uint64 deadline,bytes32 destAddr,uint16 destChainId,bytes32 referrerAddr,uint8 referrerBps,uint8 auctionMode,bytes32 random)TokenPermissions(address token,uint256 amount)"
    );

    bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
        keccak256("PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)");

    bytes32 public constant _PERMIT_SINGLE_TYPEHASH = keccak256(
        "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    function setUp() public {
        permit2 = Permit2(permit2);
        baseFork = vm.createFork(vm.envString("BASE_L2_RPC"));
    }

    function getPermitWitnessTransferSignature(
        ISignatureTransfer.PermitTransferFrom memory permit,
        uint256 privateKey,
        bytes32 typehash,
        bytes32 witness,
        address _mayanSwiftX
    ) internal view returns (bytes memory sig) {
        bytes32 tokenPermissions = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted));

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(abi.encode(typehash, tokenPermissions, _mayanSwiftX, permit.nonce, permit.deadline, witness))
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        bytes memory sigBytes = bytes.concat(r, s, bytes1(v));

        return bytes.concat(r, s, bytes1(v));
    }

    function getPermitSignature(IAllowanceTransfer.PermitSingle memory permit, uint256 privateKey)
        internal
        pure
        returns (bytes memory sig)
    {
        bytes32 permitHash = keccak256(abi.encode(_PERMIT_DETAILS_TYPEHASH, permit.details));
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(abi.encode(_PERMIT_SINGLE_TYPEHASH, permitHash, permit.spender, permit.sigDeadline))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }

    function getPermitWithOrderPayloadSignature(
        address _mayanSwiftX,
        uint256 chainId,
        bytes32 witness,
        uint256 privateKey
    ) internal pure returns (bytes memory sig) {
        bytes32 rawMsgHash = keccak256(abi.encode(_mayanSwiftX, chainId, witness));

        // "OrderPayload witness)OrderPayload(uint256 amountIn,uint256 createdAt,int64 minExecutionPrice,int64 maxExecutionPrice,uint256 createdAt,uint64 minExecutionTime,uint64 maxExecutionTime,bytes32 oracleFeedId,address tokenIn,uint256 nonce,uint8 customOrderType,OrderParams orderParams)OrderParams(bytes32 trader,bytes32 tokenOut,uint64 minAmountOut,uint64 gasDrop,uint64 cancelFee,uint64 refundFee,uint64 deadline,bytes32 destAddr,uint16 destChainId,bytes32 referrerAddr,uint8 referrerBps,uint8 auctionMode,bytes32 random)TokenPermissions(address token,uint256 amount)"
        // "OrderPayload witness)OrderPayload(uint256 amountIn,uint256 createdAt,uint256 nonce,int64 minExecutionPrice,int64 maxExecutionPrice,uint64 minExecutionTime,uint64 maxExecutionTime,uint64 minExecutionTimeInterval,uint64 maxExecutionTimeInterval,address tokenIn,uint8 noOfOrders,uint8 customOrderType,OrderParams orderParams)OrderParams(bytes32 trader,bytes32 tokenOut,uint64 minAmountOut,uint64 gasDrop,uint64 cancelFee,uint64 refundFee,uint64 deadline,bytes32 destAddr,uint16 destChainId,bytes32 referrerAddr,uint8 referrerBps,uint8 auctionMode,bytes32 random)TokenPermissions(address token,uint256 amount)"
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(rawMsgHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        require(r.length == 32 && s.length == 32 && (v == 27 || v == 28), "Invalid signature components");
        return bytes.concat(r, s, bytes1(v));
    }

    function test_InstantCustomPriceOrder() public {
        vm.selectFork(baseFork);
        mayanSwiftX = new MayanSwiftX(permit2Address, mayan, mayanForwader, pythAddress, msg.sender);

        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        uint256 nonce = 0;
        uint256 amountToSwap = 3000 * 10 ** 6;
        uint64 amountToGetAfterSwap = uint64(12 * 10 ** 18);
        bytes32 random = 0xddb9506b6a963cbbd731eb6d0042c36135128ceecb3d0c264002caadeb4200dd;
        uint8 auctionMode = 2;
        uint16 destChainID = 23;

        vm.startPrank(usdcWhale);
        IERC20(usdcAddress).transfer(alice, amountToSwap);
        vm.stopPrank();

        vm.startPrank(alice);
        IERC20(usdcAddress).approve(permit2Address, type(uint256).max);

        IPyth pyth = IPyth(pythAddress);

        PythStructs.Price memory price = pyth.getPriceNoOlderThan(ethPriceFeedId, 60);

        IMayanSwiftX.OrderPayload memory orderPayload;
        orderPayload.amountIn = amountToSwap;
        orderPayload.minExecutionPrice = price.price - 10;
        orderPayload.maxExecutionPrice = price.price + 10;
        orderPayload.createdAt = block.timestamp;
        orderPayload.minExecutionTime = uint64(block.timestamp);
        orderPayload.maxExecutionTime = uint64(block.timestamp + 1000);
        orderPayload.oracleFeedId = ethPriceFeedId;
        orderPayload.tokenIn = usdcAddress;
        orderPayload.customOrderType = IMayanSwiftX.CustomOrderType.PriceOrder;

        IMayanSwiftX.TransferPayload memory transferPayload =
            startBuildingTransferPayload(orderPayload, alice, nonce, WITNESS_TYPE_STRING);
        IMayanSwift.OrderParams memory orderParams =
            getOrderParams(orderPayload, alice, wethAddress, amountToGetAfterSwap, random, auctionMode, destChainID);

        orderPayload.orderParams = orderParams;

        bytes32 witnessHash = keccak256(abi.encode(orderPayload));
        transferPayload.witness = witnessHash;

        bytes memory sig = getPermitWitnessTransferSignature(
            transferPayload.permit, alicePk, WITNESS_TYPEHASH, transferPayload.witness, address(mayanSwiftX)
        );

        transferPayload.signature = sig;

        vm.stopPrank();

        (address executor, uint256 executorPk) = makeAddrAndKey("executor");
        vm.startPrank(executor);
        vm.deal(executor, 5 ether);
        bytes[] memory priceUpdates = new bytes[](1);
        priceUpdates[0] =
            hex"504e41550100000003b801000000040d002fb030eb4fc159b6c33a1d53c75f9bd395c39bea47b2ecb8b02f81021473a0ef0ff66ff944d7c524cd973ad07096f2881b8dd5d27e840f4f8f4155f4f904679c00020974a7e74abd4c85c8baa6821cb4a1db2de36696475b77731ac32d4a547b36d27561ab9b8e51f48f609749f574aecea2850572158e5b294688f22912e3431d9d0003797f54a5f3022c17f0f38af74bd11eb706ecf2650f53ae42d6d4732ad55833ac7b670999a503a408a8c2d5051476847ca0d8e66a1570ad97b90572d63e91288b010686c5f43d5ab424628cd092ae27b65fcd63b9a513daac756524febc338ec7ada02bd148cbbccfb22aded8bedcbc8fe5837854a41c53ea9b825b0570dddfb7cb3801081289efa83225878fa61602e81bb1196267c6d759af27ba498d4d3bb5931aad7e746a6e483efe1ab2eb620ff083fd6cb7cb9a1c9f1b94af9b09c00df34445b276010ae104d83db068bbc3e4d5bb25e12c3f775d85112bab1c1a9acce27dec0438c80d75fec817fb3171f5e89fa007642c5a35e253ea42c1ca154cb4a76cf5c372df22010b77bf8807a4156edfce1c8022ff363ebf3e361ba0c53d53899d7443b6abab4a86347773c2562f581af7238dec1e78290fb67419a00f38dd85f6474ee02f74a85f000c5b36e71c1499a3e983abfa5643d46256869ce37677d5ff87fc3bf330f684fad11563d791c14fec14684f0373388cc76f7a4d574438a3eb20a1f614a61bea151e000d56672c8b54252bdf8c318954f43a54022740f59b8625d6083186e31d43ee971a31b2f6af244fb8a12da6f000790289a11411001a48b28a38f3ed3105f4ccd0b3000ec3a2a0712f5e20c9e1e3773307506c018c99afc72897003bd0a65ddd1c3c14fe660b9092972933b67fececc6d876323fa61179024ca96a75a474f6b0552d9ebb010f978b6cbd86f73e9a0a730c9cf7a08bc9092d216be20b9f890ff7c049b2ab4e560571625ab0de39e98660626c0d119896670ceec7f9e4a7e7b231f4580aba9cf6001010875ec516a46b8bfeb096c8cc624dfc90c31a28dfa4a255b464468789c35f395d05aa493ebda6a27c46d4e444333e8e7d142c9b9080f0870705e34b1d08d21800117d7362d409a9eb778c597bc85feafe06835107d5fa7a1ab24f07b5ebd0b2294768833b935eda0e0bcc8c94a699bb575d63cb493b8a8393ddff1a9e4cd8a51fed0067c89e9200000000001ae101faedac5851e32b9b23b5f9411a8c2bac4aae3ed4dd7b811dd1a72ea4aa710000000006ff0bcf014155575600000000000c0c0fe400002710ccd48638ebdc2ce91227c0cb9c2f1087f599ad6e010055009d4294bbcd1174d6f2003ec365831e64cc31d9f6f15a2b85399db8d5000960f6000000333f82ef37000000002c767cdbfffffff80000000067c89e920000000067c89e9100000033037728e80000000023cff6980c370d16de16cfb817278614e7998b4de5583115f1fbf0350819f367670bd58b19804051e64bb91336dfa65005f4204cfa3cce0f26e547b76368bfa86d0e0122ec791965ce57a38020e07402c9d9fb40c3e206d0023d4424d487c9ce473ff5a6a9671992abb1c3a568f862a7ef4a5d6aa1c260b07cd93a3ed06fe9d0d3f3d4e7eca67c39f75aaeea51419c0c233557ffc258fa35f07e6a233f8e849401791779908f4d3b976aa9ee3c7378e54d80cc9cbdba785c452af03fd445e0930b7972b20e27fb3fc2b6e3a09308724f6e2da3ac097c1b599529e6789e89540f3ba4b9f641b88ef7e0884615bd3365a3782cf092d6";
        mayanSwiftX.execute{value: 1}(transferPayload, orderPayload, priceUpdates);

        vm.stopPrank();
    }

    function test_CustomTimeOrder() public {
        vm.selectFork(baseFork);
        mayanSwiftX = new MayanSwiftX(permit2Address, mayan, mayanForwader, pythAddress, msg.sender);

        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        uint256 nonce = 0;
        uint256 amountToSwap = 3000 * 10 ** 6;
        uint64 amountToGetAfterSwap = uint64(12 * 10 ** 18);
        bytes32 random = 0xddb9506b6a963cbbd731eb6d0042c36135128ceecb3d0c264002caadeb4200dd;
        uint8 auctionMode = 2;
        uint16 destChainID = 23;

        vm.startPrank(usdcWhale);
        IERC20(usdcAddress).transfer(alice, amountToSwap);
        vm.stopPrank();

        vm.startPrank(alice);
        IERC20(usdcAddress).approve(permit2Address, type(uint256).max);

        IMayanSwiftX.OrderPayload memory orderPayload;
        orderPayload.amountIn = amountToSwap;
        orderPayload.createdAt = block.timestamp;
        orderPayload.minExecutionTime = uint64(block.timestamp + 20);
        orderPayload.maxExecutionTime = uint64(block.timestamp + 1000);
        orderPayload.tokenIn = usdcAddress;
        orderPayload.customOrderType = IMayanSwiftX.CustomOrderType.TimeOrder;

        IMayanSwiftX.TransferPayload memory transferPayload =
            startBuildingTransferPayload(orderPayload, alice, nonce, WITNESS_TYPE_STRING);
        IMayanSwift.OrderParams memory orderParams =
            getOrderParams(orderPayload, alice, wethAddress, amountToGetAfterSwap, random, auctionMode, destChainID);

        orderPayload.nonce = transferPayload.permit.nonce;
        orderPayload.orderParams = orderParams;

        bytes32 witnessHash = keccak256(abi.encode(orderPayload));
        transferPayload.witness = witnessHash;

        bytes memory sig = getPermitWitnessTransferSignature(
            transferPayload.permit, alicePk, WITNESS_TYPEHASH, transferPayload.witness, address(mayanSwiftX)
        );

        transferPayload.signature = sig;

        vm.stopPrank();

        (address executor, uint256 executorPk) = makeAddrAndKey("executor");
        vm.startPrank(executor);
        vm.warp(block.timestamp + 22);

        vm.deal(executor, 5 ether);
        bytes[] memory priceUpdates = new bytes[](1);

        priceUpdates[0] =
            hex"504e41550100000003b801000000040d009f6addc866ae4813aa65aea5201a2b26791cf93f1a7811af36eac28419edd10365a6e6f46f3df4d865c71f3bd14d5ad77822a37027a764611f5473a9c7fbbdab010354eee0dbe64d70b8124ca689ff327471363b2a3c27a6b0ea82e887103baccda47c940f7ea4e41f01af8a0a27f21af9abf92d583205d37dc2b61e522d513cd6cd000478c17f60fdb5d9df00d5606916bd795559f13db780f0adcf5e5bd1f7761aed1d3b0db3ee55f7a8e0530c532aa049b0258dcfd691fdc6bc763e710fa4de3672cd0006b1a54772b225df52eaa35390eacf67fb3fd2a15abf45e70a98bc88f6fd42c1b26e92e1ded4e16289da5ade37caec20ef241bb6b2718addacb23124b416282746000825a139c8e42207f2c3a3fb34b4cddf9409c2f602bca4774a7c2fe720021734cd3f51638c388bdcd63543e5fccdc02336d8dc538253e0ba690c16ffe62972c005010a43a62e342bc2f1d9ddf7b30dc1402a11c8ed1e4bd6edfabee3bed34eee89981e0877a81cc27f1a979cea75b2232e869d7f69acfcbeccc04e9ac9586c9586e9dc010bbfce26081d1118942c5e3b9fd70101f7b4c7d5e418f52d3b7068b7bcaf3055f34c5488f6a6d3ac5aa9eb0b30dd414fbb9fa32c47b05816c7a73c49c7b107afad010c8e8be53e029f573dc781320c7848356ce9a5cc28fad8d3318270e7ba12ef0813587cf408c2658c73a3de6616db9b486e18408d89ff0bab4ad4dff74525ac6700010d82e92e83bd6dcfe00a100e4a13d2ad22f97c69c25ef3644aaa3574702d832fa0737f9ea2406aba2e084c61f20de679685f95b86d67afa325121a1877e124b663010eaf143f81045d193d9d0e658c1998075834cdcca611fa0e9f3ad8d455ac14e85a67f3c8913ee1ef99c80dc1fd632ee94a769c39b082a42adfb819752f29851a0e000f735123751b884915e2cfcbd99dac3be6336e6c2eeaacf150c2febd30180ffc92074b632f15a3f455d2ceb1e65c2e2a96353523c9fae6cd4368ccccae7ac7d45e0110541b3e540c9e9b96346d1158fb1646c33dadb1ef9c0b78ba128e35bc31859edb18c07cd2ebe5719c92c2bdb9cd52b7a5a5c74a4da4cccc3c0ec1295155a4ead50111c943b18416082aa4e036dce226ce9944c14e179066a3b0c1fdcd97ba0ff2c7ed03297fee569687823c32e0a16992b289af94c83e6eb872bb1c3ea7cb898f83d80067cacf7000000000001ae101faedac5851e32b9b23b5f9411a8c2bac4aae3ed4dd7b811dd1a72ea4aa71000000000704699d014155575600000000000c116deb00002710d4636e60232709ca1dfb057dfd682bfc8491334701005500ff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace0000003324660d800000000007cc4621fffffff80000000067cacf700000000067cacf6f000000330b995be00000000007d133620c3b8007ef9a49e3aea0d15647047cc6492a3aa201fb7f92c1dbf6ee34cba8dfd2f1591ecd075020f5b90e7b377fe8fafa8e5e404c40ba3593c276db3d5ba2766798e9a77685878a252022e48589b7a9600dc8defc8da4d079264b8093eeae3533c5cf372a1853a08b6a392f37e1dd11cebdb489eef953dfe69be341f7376982f1a5da1853a0aba28672cca3ddcdacd42c9013200f8cc28a400a06ef1424600b40545fdfff99af009e60079f479139560a410578b96d4a9039f0648f1a5ddc23967f1c2c7f8a5907becbc8c880d72ffce0e46f89b8fcfd770d849be8e0e86c875d6949be6ba12e926994a5dee21ab1b41c";
        mayanSwiftX.execute{value: 1}(transferPayload, orderPayload, priceUpdates);
        vm.stopPrank();
    }

    function test_CanceledCustomTimeOrder() public {
        vm.selectFork(baseFork);
        mayanSwiftX = new MayanSwiftX(permit2Address, mayan, mayanForwader, pythAddress, msg.sender);

        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        uint256 nonce = 0;
        uint256 amountToSwap = 3000 * 10 ** 6;
        uint64 amountToGetAfterSwap = uint64(12 * 10 ** 18);
        bytes32 random = 0xddb9506b6a963cbbd731eb6d0042c36135128ceecb3d0c264002caadeb4200dd;
        uint8 auctionMode = 2;
        uint16 destChainID = 23;

        vm.startPrank(usdcWhale);
        IERC20(usdcAddress).transfer(alice, amountToSwap);
        vm.stopPrank();

        vm.startPrank(alice);
        IERC20(usdcAddress).approve(permit2Address, type(uint256).max);

        IMayanSwiftX.OrderPayload memory orderPayload;
        orderPayload.amountIn = amountToSwap;
        orderPayload.createdAt = block.timestamp;
        orderPayload.minExecutionTime = uint64(block.timestamp + 20);
        orderPayload.maxExecutionTime = uint64(block.timestamp + 1000);
        orderPayload.tokenIn = usdcAddress;
        orderPayload.customOrderType = IMayanSwiftX.CustomOrderType.TimeOrder;

        IMayanSwiftX.TransferPayload memory transferPayload =
            startBuildingTransferPayload(orderPayload, alice, nonce, WITNESS_TYPE_STRING);
        IMayanSwift.OrderParams memory orderParams =
            getOrderParams(orderPayload, alice, wethAddress, amountToGetAfterSwap, random, auctionMode, destChainID);

        orderPayload.nonce = transferPayload.permit.nonce;
        orderPayload.orderParams = orderParams;

        bytes32 witnessHash = keccak256(abi.encode(orderPayload));
        transferPayload.witness = witnessHash;

        bytes memory sig = getPermitWitnessTransferSignature(
            transferPayload.permit, alicePk, WITNESS_TYPEHASH, transferPayload.witness, address(mayanSwiftX)
        );

        transferPayload.signature = sig;

        mayanSwiftX.cancelOrder(transferPayload);

        vm.stopPrank();

        (address executor, uint256 executorPk) = makeAddrAndKey("executor");
        vm.startPrank(executor);
        vm.warp(block.timestamp + 22);

        vm.deal(executor, 5 ether);
        bytes[] memory priceUpdates = new bytes[](1);

        priceUpdates[0] =
            hex"504e41550100000003b801000000040d009f6addc866ae4813aa65aea5201a2b26791cf93f1a7811af36eac28419edd10365a6e6f46f3df4d865c71f3bd14d5ad77822a37027a764611f5473a9c7fbbdab010354eee0dbe64d70b8124ca689ff327471363b2a3c27a6b0ea82e887103baccda47c940f7ea4e41f01af8a0a27f21af9abf92d583205d37dc2b61e522d513cd6cd000478c17f60fdb5d9df00d5606916bd795559f13db780f0adcf5e5bd1f7761aed1d3b0db3ee55f7a8e0530c532aa049b0258dcfd691fdc6bc763e710fa4de3672cd0006b1a54772b225df52eaa35390eacf67fb3fd2a15abf45e70a98bc88f6fd42c1b26e92e1ded4e16289da5ade37caec20ef241bb6b2718addacb23124b416282746000825a139c8e42207f2c3a3fb34b4cddf9409c2f602bca4774a7c2fe720021734cd3f51638c388bdcd63543e5fccdc02336d8dc538253e0ba690c16ffe62972c005010a43a62e342bc2f1d9ddf7b30dc1402a11c8ed1e4bd6edfabee3bed34eee89981e0877a81cc27f1a979cea75b2232e869d7f69acfcbeccc04e9ac9586c9586e9dc010bbfce26081d1118942c5e3b9fd70101f7b4c7d5e418f52d3b7068b7bcaf3055f34c5488f6a6d3ac5aa9eb0b30dd414fbb9fa32c47b05816c7a73c49c7b107afad010c8e8be53e029f573dc781320c7848356ce9a5cc28fad8d3318270e7ba12ef0813587cf408c2658c73a3de6616db9b486e18408d89ff0bab4ad4dff74525ac6700010d82e92e83bd6dcfe00a100e4a13d2ad22f97c69c25ef3644aaa3574702d832fa0737f9ea2406aba2e084c61f20de679685f95b86d67afa325121a1877e124b663010eaf143f81045d193d9d0e658c1998075834cdcca611fa0e9f3ad8d455ac14e85a67f3c8913ee1ef99c80dc1fd632ee94a769c39b082a42adfb819752f29851a0e000f735123751b884915e2cfcbd99dac3be6336e6c2eeaacf150c2febd30180ffc92074b632f15a3f455d2ceb1e65c2e2a96353523c9fae6cd4368ccccae7ac7d45e0110541b3e540c9e9b96346d1158fb1646c33dadb1ef9c0b78ba128e35bc31859edb18c07cd2ebe5719c92c2bdb9cd52b7a5a5c74a4da4cccc3c0ec1295155a4ead50111c943b18416082aa4e036dce226ce9944c14e179066a3b0c1fdcd97ba0ff2c7ed03297fee569687823c32e0a16992b289af94c83e6eb872bb1c3ea7cb898f83d80067cacf7000000000001ae101faedac5851e32b9b23b5f9411a8c2bac4aae3ed4dd7b811dd1a72ea4aa71000000000704699d014155575600000000000c116deb00002710d4636e60232709ca1dfb057dfd682bfc8491334701005500ff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace0000003324660d800000000007cc4621fffffff80000000067cacf700000000067cacf6f000000330b995be00000000007d133620c3b8007ef9a49e3aea0d15647047cc6492a3aa201fb7f92c1dbf6ee34cba8dfd2f1591ecd075020f5b90e7b377fe8fafa8e5e404c40ba3593c276db3d5ba2766798e9a77685878a252022e48589b7a9600dc8defc8da4d079264b8093eeae3533c5cf372a1853a08b6a392f37e1dd11cebdb489eef953dfe69be341f7376982f1a5da1853a0aba28672cca3ddcdacd42c9013200f8cc28a400a06ef1424600b40545fdfff99af009e60079f479139560a410578b96d4a9039f0648f1a5ddc23967f1c2c7f8a5907becbc8c880d72ffce0e46f89b8fcfd770d849be8e0e86c875d6949be6ba12e926994a5dee21ab1b41c";
        vm.expectRevert(IMayanSwiftX.CancelledOrder.selector);

        mayanSwiftX.execute{value: 1}(transferPayload, orderPayload, priceUpdates);
        vm.stopPrank();
    }

    function test_RecurringOrder() public {
        vm.selectFork(baseFork);
        vm.warp(block.timestamp - 30);
        mayanSwiftX = new MayanSwiftX(permit2Address, mayan, mayanForwader, pythAddress, msg.sender);

        IPyth pyth = IPyth(pythAddress);

        PythStructs.Price memory price = pyth.getPriceNoOlderThan(ethPriceFeedId, 60);

        uint256 amountToSwap = 3000 * 10 ** 6;
        uint64 amountToGetAfterSwap = uint64(12 * 10 ** 18);
        bytes32 random = 0xddb9506b6a963cbbd731eb6d0042c36135128ceecb3d0c264002caadeb4200dd;
        uint8 auctionMode = 2;
        uint16 destChainID = 23;

        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        vm.startPrank(usdcWhale);
        IERC20(usdcAddress).transfer(alice, amountToSwap);
        vm.stopPrank();

        vm.startPrank(alice);
        IERC20(usdcAddress).approve(permit2Address, type(uint256).max);

        IMayanSwiftX.OrderPayload memory orderPayload;
        orderPayload.minExecutionPrice = price.price - 10;
        orderPayload.maxExecutionPrice = price.price + 10;
        orderPayload.amountIn = amountToSwap;
        orderPayload.createdAt = block.timestamp;
        orderPayload.minExecutionTime = uint64(block.timestamp + 20);
        orderPayload.maxExecutionTime = uint64(block.timestamp + 1000);
        orderPayload.tokenIn = usdcAddress;
        orderPayload.noOfOrders = 2;
        orderPayload.minExecutionTimeInterval = 30;
        orderPayload.maxExecutionTimeInterval = 60;
        orderPayload.customOrderType = IMayanSwiftX.CustomOrderType.RecurringOrder;
        orderPayload.oracleFeedId = ethPriceFeedId;
    
        IMayanSwiftX.AllowancePayload memory allowancePayload =
            startBuildingAllowancePayload(orderPayload, address(mayanSwiftX));
        IMayanSwift.OrderParams memory orderParams =
            getOrderParams(orderPayload, alice, wethAddress, amountToGetAfterSwap, random, auctionMode, destChainID);

        allowancePayload.owner = alice;
         
        orderPayload.nonce = allowancePayload.permitSingle.details.nonce;
        orderPayload.orderParams = orderParams;
        bytes memory permitSig = getPermitSignature(allowancePayload.permitSingle, alicePk);
        bytes32 witness = keccak256(abi.encode(orderPayload));
        bytes memory permitWithOrderPayloadSig =
            getPermitWithOrderPayloadSignature(address(mayanSwiftX), block.chainid, witness, alicePk);

        allowancePayload.orderPayloadSignature = permitWithOrderPayloadSig;
        allowancePayload.orderHash = witness;
        allowancePayload.tokenIn = usdcAddress;
        allowancePayload.allowancePayloadSig = permitSig;
        bytes[] memory priceUpdates = new bytes[](1);

        vm.stopPrank();

        priceUpdates[0] =
            hex"504e41550100000003b801000000040d009f6addc866ae4813aa65aea5201a2b26791cf93f1a7811af36eac28419edd10365a6e6f46f3df4d865c71f3bd14d5ad77822a37027a764611f5473a9c7fbbdab010354eee0dbe64d70b8124ca689ff327471363b2a3c27a6b0ea82e887103baccda47c940f7ea4e41f01af8a0a27f21af9abf92d583205d37dc2b61e522d513cd6cd000478c17f60fdb5d9df00d5606916bd795559f13db780f0adcf5e5bd1f7761aed1d3b0db3ee55f7a8e0530c532aa049b0258dcfd691fdc6bc763e710fa4de3672cd0006b1a54772b225df52eaa35390eacf67fb3fd2a15abf45e70a98bc88f6fd42c1b26e92e1ded4e16289da5ade37caec20ef241bb6b2718addacb23124b416282746000825a139c8e42207f2c3a3fb34b4cddf9409c2f602bca4774a7c2fe720021734cd3f51638c388bdcd63543e5fccdc02336d8dc538253e0ba690c16ffe62972c005010a43a62e342bc2f1d9ddf7b30dc1402a11c8ed1e4bd6edfabee3bed34eee89981e0877a81cc27f1a979cea75b2232e869d7f69acfcbeccc04e9ac9586c9586e9dc010bbfce26081d1118942c5e3b9fd70101f7b4c7d5e418f52d3b7068b7bcaf3055f34c5488f6a6d3ac5aa9eb0b30dd414fbb9fa32c47b05816c7a73c49c7b107afad010c8e8be53e029f573dc781320c7848356ce9a5cc28fad8d3318270e7ba12ef0813587cf408c2658c73a3de6616db9b486e18408d89ff0bab4ad4dff74525ac6700010d82e92e83bd6dcfe00a100e4a13d2ad22f97c69c25ef3644aaa3574702d832fa0737f9ea2406aba2e084c61f20de679685f95b86d67afa325121a1877e124b663010eaf143f81045d193d9d0e658c1998075834cdcca611fa0e9f3ad8d455ac14e85a67f3c8913ee1ef99c80dc1fd632ee94a769c39b082a42adfb819752f29851a0e000f735123751b884915e2cfcbd99dac3be6336e6c2eeaacf150c2febd30180ffc92074b632f15a3f455d2ceb1e65c2e2a96353523c9fae6cd4368ccccae7ac7d45e0110541b3e540c9e9b96346d1158fb1646c33dadb1ef9c0b78ba128e35bc31859edb18c07cd2ebe5719c92c2bdb9cd52b7a5a5c74a4da4cccc3c0ec1295155a4ead50111c943b18416082aa4e036dce226ce9944c14e179066a3b0c1fdcd97ba0ff2c7ed03297fee569687823c32e0a16992b289af94c83e6eb872bb1c3ea7cb898f83d80067cacf7000000000001ae101faedac5851e32b9b23b5f9411a8c2bac4aae3ed4dd7b811dd1a72ea4aa71000000000704699d014155575600000000000c116deb00002710d4636e60232709ca1dfb057dfd682bfc8491334701005500ff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace0000003324660d800000000007cc4621fffffff80000000067cacf700000000067cacf6f000000330b995be00000000007d133620c3b8007ef9a49e3aea0d15647047cc6492a3aa201fb7f92c1dbf6ee34cba8dfd2f1591ecd075020f5b90e7b377fe8fafa8e5e404c40ba3593c276db3d5ba2766798e9a77685878a252022e48589b7a9600dc8defc8da4d079264b8093eeae3533c5cf372a1853a08b6a392f37e1dd11cebdb489eef953dfe69be341f7376982f1a5da1853a0aba28672cca3ddcdacd42c9013200f8cc28a400a06ef1424600b40545fdfff99af009e60079f479139560a410578b96d4a9039f0648f1a5ddc23967f1c2c7f8a5907becbc8c880d72ffce0e46f89b8fcfd770d849be8e0e86c875d6949be6ba12e926994a5dee21ab1b41c";
        (address executor, uint256 executorPk) = makeAddrAndKey("executor");
        vm.startPrank(executor);
        vm.deal(executor, 5 ether);
        vm.warp(block.timestamp + 30);
        mayanSwiftX.execute{value: 2}(allowancePayload, orderPayload, priceUpdates);
        vm.stopPrank();
    }

    function test_CanselRecurringOrder() public {
        vm.selectFork(baseFork);
        vm.warp(block.timestamp - 30);
        mayanSwiftX = new MayanSwiftX(permit2Address, mayan, mayanForwader, pythAddress, msg.sender);

        IPyth pyth = IPyth(pythAddress);

        PythStructs.Price memory price = pyth.getPriceNoOlderThan(ethPriceFeedId, 60);

        uint256 amountToSwap = 3000 * 10 ** 6;
        uint64 amountToGetAfterSwap = uint64(12 * 10 ** 18);
        bytes32 random = 0xddb9506b6a963cbbd731eb6d0042c36135128ceecb3d0c264002caadeb4200dd;
        uint8 auctionMode = 2;
        uint16 destChainID = 23;

        (address alice, uint256 alicePk) = makeAddrAndKey("alice");
        vm.startPrank(usdcWhale);
        IERC20(usdcAddress).transfer(alice, amountToSwap);
        vm.stopPrank();

        vm.startPrank(alice);
        IERC20(usdcAddress).approve(permit2Address, type(uint256).max);

        IMayanSwiftX.OrderPayload memory orderPayload;
        orderPayload.minExecutionPrice = price.price - 10;
        orderPayload.maxExecutionPrice = price.price + 10;
        orderPayload.amountIn = amountToSwap;
        orderPayload.createdAt = block.timestamp;
        orderPayload.minExecutionTime = uint64(block.timestamp + 20);
        orderPayload.maxExecutionTime = uint64(block.timestamp + 1000);
        orderPayload.tokenIn = usdcAddress;
        orderPayload.noOfOrders = 2;
        orderPayload.minExecutionTimeInterval = 30;
        orderPayload.maxExecutionTimeInterval = 60;
        orderPayload.customOrderType = IMayanSwiftX.CustomOrderType.RecurringOrder;
        orderPayload.oracleFeedId = ethPriceFeedId;

        IMayanSwiftX.AllowancePayload memory allowancePayload =
            startBuildingAllowancePayload(orderPayload, address(mayanSwiftX));
        IMayanSwift.OrderParams memory orderParams =
            getOrderParams(orderPayload, alice, wethAddress, amountToGetAfterSwap, random, auctionMode, destChainID);

        allowancePayload.owner = alice;

        orderPayload.nonce = allowancePayload.permitSingle.details.nonce;
        orderPayload.orderParams = orderParams;
        bytes memory permitSig = getPermitSignature(allowancePayload.permitSingle, alicePk);
        bytes32 witness = keccak256(abi.encode(orderPayload));
        bytes memory permitWithOrderPayloadSig =
            getPermitWithOrderPayloadSignature(address(mayanSwiftX), block.chainid, witness, alicePk);

        allowancePayload.orderPayloadSignature = permitWithOrderPayloadSig;
        allowancePayload.orderHash = witness;
        allowancePayload.tokenIn = usdcAddress;
        allowancePayload.allowancePayloadSig = permitSig;
        bytes[] memory priceUpdates = new bytes[](1);
        mayanSwiftX.cancelOrder(allowancePayload, witness);
        vm.stopPrank();

        priceUpdates[0] =
            hex"504e41550100000003b801000000040d009f6addc866ae4813aa65aea5201a2b26791cf93f1a7811af36eac28419edd10365a6e6f46f3df4d865c71f3bd14d5ad77822a37027a764611f5473a9c7fbbdab010354eee0dbe64d70b8124ca689ff327471363b2a3c27a6b0ea82e887103baccda47c940f7ea4e41f01af8a0a27f21af9abf92d583205d37dc2b61e522d513cd6cd000478c17f60fdb5d9df00d5606916bd795559f13db780f0adcf5e5bd1f7761aed1d3b0db3ee55f7a8e0530c532aa049b0258dcfd691fdc6bc763e710fa4de3672cd0006b1a54772b225df52eaa35390eacf67fb3fd2a15abf45e70a98bc88f6fd42c1b26e92e1ded4e16289da5ade37caec20ef241bb6b2718addacb23124b416282746000825a139c8e42207f2c3a3fb34b4cddf9409c2f602bca4774a7c2fe720021734cd3f51638c388bdcd63543e5fccdc02336d8dc538253e0ba690c16ffe62972c005010a43a62e342bc2f1d9ddf7b30dc1402a11c8ed1e4bd6edfabee3bed34eee89981e0877a81cc27f1a979cea75b2232e869d7f69acfcbeccc04e9ac9586c9586e9dc010bbfce26081d1118942c5e3b9fd70101f7b4c7d5e418f52d3b7068b7bcaf3055f34c5488f6a6d3ac5aa9eb0b30dd414fbb9fa32c47b05816c7a73c49c7b107afad010c8e8be53e029f573dc781320c7848356ce9a5cc28fad8d3318270e7ba12ef0813587cf408c2658c73a3de6616db9b486e18408d89ff0bab4ad4dff74525ac6700010d82e92e83bd6dcfe00a100e4a13d2ad22f97c69c25ef3644aaa3574702d832fa0737f9ea2406aba2e084c61f20de679685f95b86d67afa325121a1877e124b663010eaf143f81045d193d9d0e658c1998075834cdcca611fa0e9f3ad8d455ac14e85a67f3c8913ee1ef99c80dc1fd632ee94a769c39b082a42adfb819752f29851a0e000f735123751b884915e2cfcbd99dac3be6336e6c2eeaacf150c2febd30180ffc92074b632f15a3f455d2ceb1e65c2e2a96353523c9fae6cd4368ccccae7ac7d45e0110541b3e540c9e9b96346d1158fb1646c33dadb1ef9c0b78ba128e35bc31859edb18c07cd2ebe5719c92c2bdb9cd52b7a5a5c74a4da4cccc3c0ec1295155a4ead50111c943b18416082aa4e036dce226ce9944c14e179066a3b0c1fdcd97ba0ff2c7ed03297fee569687823c32e0a16992b289af94c83e6eb872bb1c3ea7cb898f83d80067cacf7000000000001ae101faedac5851e32b9b23b5f9411a8c2bac4aae3ed4dd7b811dd1a72ea4aa71000000000704699d014155575600000000000c116deb00002710d4636e60232709ca1dfb057dfd682bfc8491334701005500ff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace0000003324660d800000000007cc4621fffffff80000000067cacf700000000067cacf6f000000330b995be00000000007d133620c3b8007ef9a49e3aea0d15647047cc6492a3aa201fb7f92c1dbf6ee34cba8dfd2f1591ecd075020f5b90e7b377fe8fafa8e5e404c40ba3593c276db3d5ba2766798e9a77685878a252022e48589b7a9600dc8defc8da4d079264b8093eeae3533c5cf372a1853a08b6a392f37e1dd11cebdb489eef953dfe69be341f7376982f1a5da1853a0aba28672cca3ddcdacd42c9013200f8cc28a400a06ef1424600b40545fdfff99af009e60079f479139560a410578b96d4a9039f0648f1a5ddc23967f1c2c7f8a5907becbc8c880d72ffce0e46f89b8fcfd770d849be8e0e86c875d6949be6ba12e926994a5dee21ab1b41c";
        (address executor, uint256 executorPk) = makeAddrAndKey("executor");
        vm.startPrank(executor);
        vm.deal(executor, 5 ether);

        vm.warp(block.timestamp + 30);
        vm.expectRevert(IMayanSwiftX.CancelledOrder.selector);
        mayanSwiftX.execute{value: 2}(allowancePayload, orderPayload, priceUpdates);
        vm.stopPrank();
    }

    function startBuildingTransferPayload(
        IMayanSwiftX.OrderPayload memory orderPayload,
        address owner,
        uint256 nonce,
        string memory witnessTypeString
    ) public returns (IMayanSwiftX.TransferPayload memory payload) {
        payload.permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: orderPayload.tokenIn, amount: orderPayload.amountIn}),
            nonce: nonce,
            deadline: orderPayload.maxExecutionTime
        });

        payload.transferDetails =
            ISignatureTransfer.SignatureTransferDetails(address(mayanSwiftX), orderPayload.amountIn);
        payload.owner = owner;
        payload.witnessTypeString = witnessTypeString;
        payload.signature = "";

        return payload;
    }

    function startBuildingAllowancePayload(IMayanSwiftX.OrderPayload memory orderPayload, address spender)
        public
        returns (IMayanSwiftX.AllowancePayload memory payload)
    {
        require(orderPayload.amountIn <= type(uint160).max, "amountIn too large");
        require(orderPayload.maxExecutionTime <= type(uint48).max, "maxExecutionTime too large");
        require(orderPayload.nonce <= type(uint48).max, "nonce too large");

        IAllowanceTransfer.PermitDetails memory details = IAllowanceTransfer.PermitDetails({
            token: orderPayload.tokenIn,
            amount: uint160(orderPayload.amountIn),
            expiration: uint48(orderPayload.maxExecutionTime),
            nonce: uint48(orderPayload.nonce)
        });
      
        IAllowanceTransfer.PermitSingle memory permitSingle = IAllowanceTransfer.PermitSingle({
            details: details,
            spender: spender,
            sigDeadline: orderPayload.maxExecutionTime
        });

        payload.permitSingle = permitSingle;

        return payload;
    }

    function getOrderParams(
        IMayanSwiftX.OrderPayload memory orderPayload,
        address owner,
        address tokenOut,
        uint64 minAmountOut,
        bytes32 random,
        uint8 auctionMode,
        uint16 destChainId
    ) public returns (IMayanSwift.OrderParams memory orderParams) {
        orderParams.trader = addressToBytes32(owner);
        orderParams.tokenOut = addressToBytes32(tokenOut);
        orderParams.minAmountOut = minAmountOut;
        orderParams.gasDrop = 0;
        orderParams.cancelFee = 0;
        orderParams.refundFee = 0;
        orderParams.deadline = orderPayload.maxExecutionTime;
        orderParams.destAddr = addressToBytes32(owner);
        orderParams.destChainId = destChainId;
        orderParams.referrerAddr = bytes32(0);
        orderParams.referrerBps = 0;
        orderParams.auctionMode = auctionMode;
        orderParams.random = random;
        return orderParams;
    }

    function addressToBytes32(address addr) public pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}
