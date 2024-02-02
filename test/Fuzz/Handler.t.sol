// SPDX-License-Identifier: MIT
// They are more specific...handler is going to narrow down the way we call function

pragma solidity 0.8.20;

// import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract Handler is Test {
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    MockV3Aggregator public ethUsdPriceFeed;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max; // the max uint96 value
        // making because it must know DSC engine
        // beccause these are the contracts that we want Handler to handle making calls to

    uint256 public timesMintIsCalled;
    address[] public userWithCollateralDeposited;

    constructor(DSCEngine _dsce, DecentralizedStableCoin _dsc) {
        dsce = _dsce;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        ethUsdPriceFeed = MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));
    }

    // ex -  Do not call the reedem collateral unless there is collateral to readmeam!
    // reedem Collateral ->
    // but for that first we want deposite collateral

    // here putting parameter for randomizati on
    // with collateralSeed we will let it pick randomize the wbtc, or weth
    function depoitCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        // bound(bound to what, 0, 0)
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);
        vm.startPrank(msg.sender);
        // miniting collateral from ERC20 Mock and then approving it add of this contract
        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);
        dsce.depositCollateral(address(collateral), amountCollateral);
        vm.stopPrank();
        // double push - should have checked
        userWithCollateralDeposited.push(msg.sender);
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        if (userWithCollateralDeposited.length == 0) {
            return;
        }

        address sender = userWithCollateralDeposited[addressSeed % userWithCollateralDeposited.length];

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(sender);
        int256 maxDscToMint = (int256(collateralValueInUsd) / 2) - int256(totalDscMinted);
        if (maxDscToMint < 0) {
            return;
        }

        amount = bound(amount, 1, MAX_DEPOSIT_SIZE);
        if (amount == 0) {
            return;
        }
        timesMintIsCalled++;
        vm.startPrank(sender);
        dsce.mintDsc(amount);
        vm.stopPrank();
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);
        uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(address(collateral), msg.sender);
        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem);
        if (amountCollateral == 0) {
            return;
        }
        //  we are using v,.assume
        if (amountCollateral == 0) {
            return;
        }
        dsce.redeemCollateral(address(collateral), amountCollateral);
    }

    function updateCollateralPrice(uint96 newPrice) public {
        int256 newPriceInt = int256(uint256(newPrice));
        ethUsdPriceFeed.updateAnswer(newPriceInt);
    }

    // now instead of choosing any address we have given only 2 typs of randome add choice
    // valid collateral address
    function _getCollateralFromSeed(uint256 CollateralSeed) private view returns (ERC20Mock) {
        if (CollateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}

// continue on revert -> Gives Revert -> they are quicker looser test, which are small are arent more narrow down
// Fail on Revert -> 0 Reverts -> All tests pass 100% of the time wiothout o
