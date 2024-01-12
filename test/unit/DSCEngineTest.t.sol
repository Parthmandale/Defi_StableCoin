//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
// import {MockFailedMintDSC} from "../mocks/MockFailedMintDSC.sol";

contract DSCEngineTest is Test {
    DSCEngine public dsce;
    DecentralizedStableCoin public dsc;
    DeployDSC public deployer;
    HelperConfig public config;

    address public ethUsdPriceFeed;
    address public btcUsdPriceFeed;
    address public weth;
    address public wbtc;
    uint256 public deployerKey;

    // address public USER = makeAddr("user");
    address public user = address(1);
    uint256 public amountCollateral = 10 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 amountToMint = 100 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE); // here weth is the token address
        ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
    }

    /* 
    function setUp() external {
        DeployDSC deployer = new DeployDSC();
        (dsc, dsce, helperConfig) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc, deployerKey) = helperConfig.activeNetworkConfig();
        if (block.chainid == 31337) {
            vm.deal(user, STARTING_USER_BALANCE);
        }
        // Should we put our integration tests here?
        // else {
        //     user = vm.addr(deployerKey);
        //     ERC20Mock mockErc = new ERC20Mock("MOCK", "MOCK", user, 100e18);
        //     MockV3Aggregator aggregatorMock = new MockV3Aggregator(
        //         helperConfig.DECIMALS(),
        //         helperConfig.ETH_USD_PRICE()
        //     );
        //     vm.etch(weth, address(mockErc).code);
        //     vm.etch(wbtc, address(mockErc).code);
        //     vm.etch(ethUsdPriceFeed, address(aggregatorMock).code);
        //     vm.etch(btcUsdPriceFeed, address(aggregatorMock).code);
        // }
        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE);
        ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
    }
    */

    address[] public tokenAddresses;
    address[] public feedAddresses;
    // Constructor test

    modifier depositedCollateral() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateral(weth, amountCollateral);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMintedDsc() {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);
        dsce.depositCollateralAndMintDsc(weth, amountCollateral, amountToMint);
        vm.stopPrank();
        _;
    }

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        feedAddresses.push(ethUsdPriceFeed);
        feedAddresses.push(btcUsdPriceFeed);

        //Here using DSCEngine because it in EXPECTREVERT, and it is a contract and we can use selector
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
            // approving 10 ether to DSCEngine contract
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector); // selector because it has value in it(Parameter)
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        // ERC20Mock -> constructor(string memory name, string memory symbol, address initialAccount, uint256 initialBalance)
        ERC20Mock MockToken = new ERC20Mock("Solana", "SOL", user, 100e18);
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__TokenNotAllowed.selector, address(MockToken)));
        // selector because it has value in it(Parameter), after comma we are passing the parameter
        dsce.depositCollateral(weth, 0);
        dsce.depositCollateral(address(MockToken), amountCollateral);
        vm.stopPrank();
    }

    // function testGetTokenAmountFromUsd() public {
    //     // here ethUsdPriceFeed in helper config we have set 2000, but on testnet it will fetched from chainlink
    //     // If we want $100 of WETH and (one single WETH is of $2000), that would be - 100/2000 ->  0.05 WETH ->
    //     uint256 expectedWeth = 0.05 ether;
    //     uint256 amountWeth = dsce.getTokenAmountFromUsd(weth, 100);
    //     assertEq(expectedWeth, amountWeth);
    // }

    // function testCanDepositCollateralWithoutMinting() public depositedCollateral {
    //     uint256 userBalance = dsc.balanceOf(user);
    //     assertEq(userBalance, 0);
    // }

    //  function testCanDepositedCollateralAndGetAccountInfo() public depositedCollateral {
    //     (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(user);
    //     //function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) public view returns (uint256) {
    //     uint256 expectedDepositedAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
    //     assertEq(totalDscMinted, 0);
    //     assertEq(expectedDepositedAmount, amountCollateral);
    // }

    function testRevertsIfMintedDscBreaksHealthFactor() public {
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        amountToMint = (amountCollateral * uint256(price) * dsce.getAdditionalFeedPrecision()) / dsce.getPrecision();

        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);

        uint256 expectHealthFactor = dsce.calculateHealthFactor(amountToMint, dsce.getUsdValue(weth, amountCollateral));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectHealthFactor));
        dsce.depositCollateralAndMintDsc(weth, amountCollateral, amountToMint);
        vm.stopPrank();
    }

    /* 
    function testRevertsIfMintedDscBreaksHealthFactor() public {
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        amountToMint = (amountCollateral * (uint256(price) * dsce.getAdditionalFeedPrecision())) / dsce.getPrecision();
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral);

        uint256 expectedHealthFactor =
            dsce.calculateHealthFactor(amountToMint, dsce.getUsdValue(weth, amountCollateral));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
        dsce.depositCollateralAndMintDsc(weth, amountCollateral, amountToMint);
        vm.stopPrank();
    }
    */
    // mintDsc Tests //

    // function testRevertsIfMintFails() public {
    //     // Arrange - Setup
    //     MockFailedMintDSC mockDsc = new MockFailedMintDSC();
    //     tokenAddresses = [weth];
    //     feedAddresses = [ethUsdPriceFeed];
    //     address owner = msg.sender;
    //     vm.prank(owner);
    //     DSCEngine mockDsce = new DSCEngine(
    //         tokenAddresses,
    //         feedAddresses,
    //         address(mockDsc)
    //     );
    //     mockDsc.transferOwnership(address(mockDsce));
    //     // Arrange - User
    //     vm.startPrank(user);
    //     ERC20Mock(weth).approve(address(mockDsce), amountCollateral);

    //     vm.expectRevert(DSCEngine.DSCEngine__MintFailed.selector);
    //     mockDsce.depositCollateralAndMintDsc(weth, amountCollateral, amountToMint);
    //     vm.stopPrank();
    // }

    function testRevertsIfMintAmountIsZero() public depositedCollateral {
        vm.prank(user);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.mintDsc(0);
    }
}

// ----------------------------------------------------------------------------------------------------
