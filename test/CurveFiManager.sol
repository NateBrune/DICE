pragma solidity >=0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
//import "../contracts/CurveFiManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils.sol";

contract TestCurveFiManager {
  address userAddress = 0x9eB7f2591ED42dEe9315b6e2AAF21bA85EA69F8C; // must be --unlocked on ganache
  address daiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // must be --unlocked on ganache
  address constant usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address constant curveFi_curve_cDai_cUsdc = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
  address constant curveFi_curve_ypool = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
  address constant curveFi_curve_sUsd_bestpool = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
  address constant vaultMangagerAddress = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

  function testGetSwapPrice() public {
    CurveFiManagerLike curve = CurveFiManagerLike(DeployedAddresses.CurveFiManager());
    uint256 amt = 1 ether;
    uint256 r = curve.getSwapPrice(0, 1, amt);
    Assert.isAbove(r, 1, "Couldn't fetch swap price");
  }

  function testApproval() public {
    CurveFiManagerLike curve = CurveFiManagerLike(DeployedAddresses.CurveFiManager());
    bool result = curve.getApproval();
    Assert.equal(result, true, "Couldn't get approval");
    IERC20 Dai = IERC20(daiAddress);
    uint256 allowance = Dai.allowance(DeployedAddresses.CurveFiManager(), curveFi_curve_sUsd_bestpool);
    Assert.equal(allowance, (2**256)-1, "This contract is not allowed to spend Dai");
    IERC20 Usdc = IERC20(usdcAddress);
    uint256 allowance2 = Usdc.allowance(DeployedAddresses.CurveFiManager(), curveFi_curve_sUsd_bestpool);
    Assert.equal(allowance2, (2**256)-1, "This contract is not allowed to spend Usdc");
  }
  
  function testBuild() public {
    CurveFiManagerLike curve = CurveFiManagerLike(DeployedAddresses.CurveFiManager());
    address proxy = curve.buildProxy();
    Assert.notEqual(proxy, address(0), "Could not build proxy");
  }
  

  function testOpenVault() public {
    CurveFiManagerLike curve = CurveFiManagerLike(DeployedAddresses.CurveFiManager());
    uint256 vault = curve.openVault();
    Assert.isAbove(vault, 0, "Couldn't open vault");
  }
  /*
  function mintDai(uint256 wad) public returns (bool) {
    IERC20 Dai = IERC20(daiAddress);
    //Dai.allowance[userAddress][address(this)] = (2**256)-1; // this is not a thing!
    //Dai.approve(address(this), (2**256)-1);
    return Dai.transferFrom(userAddress, address(this), wad);
  }

  function testMintDai() public {
    uint256 wad = 10000000000000000000000; // 10000 * 1000000000000000000
    mintDai(wad);
    IERC20 Dai = IERC20(daiAddress);
    Assert.equal(wad, Dai.balanceOf(address(this)), "Dai was not transferred to test account.");
  }
  /*
  function testShort() public {
    CurveFiManager curve = CurveFiManager(DeployedAddresses.CurveFiManager());
    curve.initateFlashLoan("");
  }
  */
}