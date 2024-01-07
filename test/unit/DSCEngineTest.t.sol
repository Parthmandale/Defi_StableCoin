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
    address weth;
    address wbtc;

    address public user = address(1);
    uint256 public amountCollateral = 10 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();
        ERC20Mock(weth).mint(user, STARTING_USER_BALANCE); // here weth is the token address
            // ERC20Mock(wbtc).mint(user, STARTING_USER_BALANCE);
    }

    // Test start

    // Testing price feed
    function testGetUsdValue() public {
        uint256 ethAmount = 15e18; //one single eth is 2000 usd
        //     int256 public constant ETH_USD_PRICE = 2000e8;
        uint256 Excpectedusd = 30000e18; // hardcoded = 15 * 2000

        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);

        assertEq(Excpectedusd, actualUsd);
    }

    function testRevertIfCollateralIsZero() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(dsce), amountCollateral); // approve function is from openzeppelin in

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);
        vm.stopPrank();
    }
}
