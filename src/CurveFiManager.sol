pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "@studydefi/money-legos/curvefi/contracts/ICurveFiCurve.sol";

import "@studydefi/money-legos/aave/contracts/ILendingPool.sol";
import "@studydefi/money-legos/aave/contracts/IFlashLoanReceiver.sol";
import "@studydefi/money-legos/aave/contracts/FlashloanReceiverBase.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./VaultManager.sol";

contract CurveFiManager is FlashLoanReceiverBase {
    address constant curveFi_curve_cDai_cUsdc = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address constant AaveLendingPoolAddressProviderAddress = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
    //address constant DaiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    //address constant UsdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    int128 constant daiIndex = 0;
    int128 constant usdcIndex = 1;
    //struct FlashloanData {
    //    address daiAddress;
    //    address usdcAddress;
    //}
    
    constructor(address vault_manager, address dssCdpManager, address jug, address daiJoin, address usdcJoin, address dai, address usdc) public { 
        owner = msg.sender; 
        _vaultManagerAddress = vault_manager;
        _dssCdpManagerAddress = dssCdpManager;
        _jugAddress = jug;
        _daiJoinAddress = daiJoin;
        _usdcJoinAddress = usdcJoin;
        daiAddress = dai;
        usdcAddress = usdc;
    }
    address payable owner;
    address _vaultManagerAddress;
    address _dssCdpManagerAddress;
    address _jugAddress;
    address _daiJoinAddress;
    address _usdcJoinAddress;
    address daiAddress;
    address usdcAddress;

    function getSwapPrice(int128 from, int128 to, uint256 amount) external returns (uint) {
        ICurveFiCurve curve = ICurveFiCurve(curveFi_curve_cDai_cUsdc);
        return curve.get_dy_underlying(from, to, amount);
    }

    function swap(int128 from, int128 to, uint256 amount) external {
        ICurveFiCurve curve = ICurveFiCurve(curveFi_curve_cDai_cUsdc);
        curve.exchange_underlying(from, to, amount, 1);
    }

    function executeOperation(
        address _reserve,
        uint _amount,
        uint _fee,
        bytes calldata _params
    ) external {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        IERC20 Dai = IERC20(daiAddress);
        uint256 balance = Dai.balanceOf(address(this));
        uint total_dai = _amount.add(balance);
        uint min_requested = this.getSwapPrice(daiIndex, usdcIndex, total_dai);
        uint converted = min_requested.mul(1000000000000);
        require(converted > total_dai, "Dai is not worth more than USDC");
        this.swap(daiIndex, usdcIndex, total_dai);
        uint usdcBalance = getBalanceInternal(address(this), usdcAddress);
        require(min_requested <= usdcBalance, "Was swap successful?");
        VaultManager vault = VaultManager(_vaultManagerAddress);
        vault.openUsdcVault(_vaultManagerAddress, _jugAddress, _usdcJoinAddress, _daiJoinAddress, 6, usdcBalance);
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    // Entry point
    function initateFlashLoan(bytes calldata _params) external {
        // Get Aave lending pool
        ILendingPool lendingPool = ILendingPool(
            ILendingPoolAddressesProvider(AaveLendingPoolAddressProviderAddress)
                .getLendingPool()
        );
        
        IERC20 Dai = IERC20(daiAddress);
        uint256 balance = Dai.balanceOf(address(this));
        uint256 loan = SafeMath.mul(balance, 10);
        require(balance > 0, "No collateral available.");
        //FlashloanData memory _params;
        //_params.collateral = balance;
        //_params.loan = loan;

        // Ask for a flashloan
        // Calls executeOperation function above
        lendingPool.flashLoan(
            address(this), // Which address to callback into, alternatively: address(this)
            address(Dai), // Asset to flash loan
            loan,
            _params
        );
    }

}