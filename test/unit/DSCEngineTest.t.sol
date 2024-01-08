//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract DSCEngineTest is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    DeployDSC deployer;
    HelperConfig config;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;
    uint256 public deployerKey;

    address public USER = makeAddr("user");
    address public user = address(1);
    uint256 public amountCollateral = 10 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE); // here weth is the token address
        ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
    }

    address[] public tokenAddresses;
    address[] public feedAddresses;
    // Constructor test

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressesAndPriceFeedAddressesAmountsDontMatch.selector); // selectoer because it is error
        new DSCEngine(tokenAddresses, feedAddresses, address(dsc));
    }

    // Testing price feed
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18; //one single eth is 2000 usd
        //  written in helper config int256 public constant ETH_USD_PRICE = 2000e8;
        uint256 Excpectedusd = 30000e18; // hardcoded = 15 * 2000

        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);

        assertEq(Excpectedusd, actualUsd);
    }

    function testRevertIfCollateralIsZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral); // approve function is from ERC20 contract

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    //  ERROR in this test
    // function testGetTokenAmountFromUsd() public {
    //     // here ethUsdPriceFeed in helper config we have set 2000, but on testnet it will fetched from chainlink
    //     // If we want $100 of WETH and one single WETH is -> $2000/WETH, that would be - 100/2000 ->  0.1 WETH ->
    //     uint256 expectedWeth = 0.05 ether;
    //     uint256 amountWeth = dsce.getTokenAmountFromUsd(weth, 100 ether);
    //     assertEq(expectedWeth, amountWeth);
    // }

    // ERROR here also
    function testRevertsWithUnapprovedCollateral() public {
        // ERC20Mock -> constructor(string memory name, string memory symbol, address initialAccount, uint256 initialBalance)
        ERC20Mock MockToken = new ERC20Mock("Solana", "SOL", user, 100e18);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        dsce.depositCollateral(address(MockToken), amountCollateral);
        vm.stopPrank();
    }
}
