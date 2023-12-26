//  SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    DeployDSC deployer;
    HelperConfig config;
    address ethUsdPriceFeed;
    address weth;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();
    }

    // Test start

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18; //eath is 2000 usd

        uint256 Excpectedusd = 30000e18;

        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);

        assertEq(Excpectedusd, actualUsd);
    }
}
