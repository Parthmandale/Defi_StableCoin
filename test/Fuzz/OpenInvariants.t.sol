// SPDX-License-Identifier: MIT
// pragma solidity 0.8.20;

// // Invariants properties
// // whatare our invariants>

// // 1. the total supply of DSC should should be less than the total value of collateral
// // 2. Getter view functions should never revert -> this are evergreen invariants

// import {StdInvariant} from "forge-std/StdInvariant.sol";
// import {Test, console} from "forge-std/Test.sol";
// import {DeployDSC} from "../../script/DeployDSC.s.sol";
// import {HelperConfig} from "../../script/HelperConfig.s.sol";
// import {DSCEngine} from "../../src/DSCEngine.sol";
// import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
// import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

// contract OpenInvariantsTest is StdInvariant, Test {
//     DeployDSC deployer;
//     DSCEngine dsce;
//     DecentralizedStableCoin dsc;
//     HelperConfig config;

//     address public ethUsdPriceFeed;
//     address public btcUsdPriceFeed;
//     address public weth;
//     address public wbtc;

//     function setUp() external {
//         deployer = new DeployDSC();
//         (dsc, dsce, config) = deployer.run();

//         (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();
//         targetContract(address(dsce));
//     }

//     function invariant_protocolMustHaveMoreColletalThanTotalSupply() public view {
//         uint256 totalSupply = dsc.totalSupply();
//         uint256 wethDeposted = ERC20Mock(weth).balanceOf(address(dsce));
//         uint256 wbtcDeposited = ERC20Mock(wbtc).balanceOf(address(dsce));

//         uint256 wethValue = dsce.getUsdValue(weth, wethDeposted);
//         uint256 wbtcValue = dsce.getUsdValue(wbtc, wbtcDeposited);

//         console.log("wethValue: %s", wethValue);
//         console.log("wbtcValue: %s", wbtcValue);
//         assert(wethValue + wbtcValue >= totalSupply);
//     }
// }
