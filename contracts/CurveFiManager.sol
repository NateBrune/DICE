pragma solidity >=0.5.0;
//pragma experimental ABIEncoderV2;

import "@studydefi/money-legos/curvefi/contracts/ICurveFiCurve.sol";

import "@studydefi/money-legos/aave/contracts/ILendingPool.sol";
import "@studydefi/money-legos/aave/contracts/IFlashLoanReceiver.sol";
import "@studydefi/money-legos/aave/contracts/FlashloanReceiverBase.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./lib/dss-interfaces/src/Interfaces.sol";
import "./lib/ds-proxy/src/proxy.sol";

contract CurveFiManager is FlashLoanReceiverBase {
    address constant curveFi_curve_cDai_cUsdc = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address constant curveFi_curve_ypool = 0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51;
    address constant curveFi_curve_sUsd_bestpool = 0xA5407eAE9Ba41422680e2e00537571bcC53efBfD;
    address constant AaveLendingPoolAddressProviderAddress = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;
    //address constant DaiAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    //address constant UsdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    int128 constant daiIndex = 0;
    int128 constant usdcIndex = 1;
    //struct FlashloanData {
    //    address daiAddress;
    //    address usdcAddress;
    //}
    
    constructor(address dssCdpManager, address proxyRegistry, address jug, address daiJoin, address usdcJoin, address dai, address usdc) public { 
        owner = msg.sender; 
        _dssCdpManagerAddress = dssCdpManager;
        _proxyRegistryAddress = proxyRegistry;
        _jugAddress = jug;
        _daiJoinAddress = daiJoin;
        _usdcJoinAddress = usdcJoin;
        daiAddress = dai;
        usdcAddress = usdc;
    }
    address payable public owner;
    address public _vaultManagerAddress;
    address public _dssCdpManagerAddress;
    address public _jugAddress;
    address public _daiJoinAddress;
    address public _usdcJoinAddress;
    address daiAddress;
    address usdcAddress;
    address public _proxyRegistryAddress;
    address payable public _ourProxyAddress = address(0);
    uint256 vaulted = 0;
    uint256 debt = 0;
    uint256 _cdpID = 0;
    bool inPosition = false;
   

    function getSwapPrice(int128 from, int128 to, uint256 amount) external returns (uint) {
        ICurveFiCurve curve = ICurveFiCurve(curveFi_curve_sUsd_bestpool);
        return curve.get_dy_underlying(from, to, amount);
    }

    function swapDaiToUsdc(uint256 amount) external {
        IERC20 Dai = IERC20(daiAddress);
        uint256 balance = Dai.balanceOf(address(this));
        require(balance > 0, "No Dai available!");
        require(amount <= balance, "Not enough Dai available!");

        uint256 allowance = Dai.allowance(address(this), curveFi_curve_sUsd_bestpool);
        require(allowance >= amount, "This contract is not allowed to spend Dai!");

        IERC20 Usdc = IERC20(usdcAddress);
        uint256 allowance2 = Usdc.allowance(address(this), curveFi_curve_sUsd_bestpool);
        require(allowance2 >= amount, "This contract is not allowed to spend Usdc!");

        ICurveFiCurve curve = ICurveFiCurve(curveFi_curve_sUsd_bestpool);
        curve.exchange_underlying(daiIndex, usdcIndex, amount, 1);
    }

    function getApproval() external returns (bool) {
        IERC20 Dai = IERC20(daiAddress);
        bool statusDai = Dai.approve(curveFi_curve_sUsd_bestpool, (2**256)-1);
        IERC20 Usdc = IERC20(usdcAddress);
        bool statusUsdc = Usdc.approve(curveFi_curve_sUsd_bestpool, (2**256)-1);
        bool statusDaiVault = Dai.approve(_daiJoinAddress, (2**256)-1);
        bool statusUsdcVault = Usdc.approve(_usdcJoinAddress, (2**256)-1);
        bool statusDaiProxy = Dai.approve(_ourProxyAddress, (2**256)-1);
        bool statusUsdcProxy = Usdc.approve(_ourProxyAddress, (2**256)-1);
        return statusDai && statusUsdc && statusDaiVault && statusUsdcVault && statusDaiProxy && statusUsdcProxy;
    }

    
    function buildProxy() external returns (address){
        if(_ourProxyAddress != address(0)) return _ourProxyAddress;
        address payable _proxy = DSProxyFactory(_proxyRegistryAddress).build(address(this));
        require(_proxy != address(0), "Failed to build proxy");
        _ourProxyAddress = _proxy;
        return _proxy;
    }

    /*
    function openVault() external returns (uint) {
        VaultManager vault = VaultManager(_vaultManagerAddress);
        uint cdp = vault.openUsdcVault(_dssCdpManagerAddress, address(this));
        if(cdp != 0 ){
            _cdp = cdp;
        }
        return cdp;
    }
    
    function openVault() external returns (uint) {
        IDssProxyActions vault = IDssProxyActions(_ourProxyAddress);
        bytes32 ilk = bytes32("USDC-A");
        if(_cdp == 0){
            _cdp = vault.open(_dssCdpManagerAddress, ilk, address(this));
            return _cdp;
        }
        return 0;
    }

    function openVault() external returns (uint) {
        ManagerLike manager = ManagerLike(_dssCdpManagerAddress); 
        bytes32 ilk = bytes32("USDC-A");
        if(_cdp == 0){
            _cdp = manager.open(ilk, address(this));
            return _cdp;
        }
        return 0;
    }
    */
    // stolen from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L370-L379
    function toUint256(bytes calldata _bytes, uint256 _start) external pure returns (uint256) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        uint256 tempUint;
        bytes memory data = _bytes;
        assembly {
            tempUint := mload(add(add(data, 0x20), _start))
        }

        return tempUint;
    }

    address payable constant _dssProxyActionsAddress = 0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038; //TODO: add to init
    function openVault() external returns (uint) {
        if(_cdpID != 0) return _cdpID;
        require(_ourProxyAddress != address(0), "No proxy built.");
        
        IERC20 Dai = IERC20(daiAddress);
        IERC20 Usdc = IERC20(usdcAddress);
        
        bool statusDaiProxy = Dai.approve(_ourProxyAddress, (2**256)-1);
        bool statusUsdcProxy = Usdc.approve(_ourProxyAddress, (2**256)-1);
        require(statusDaiProxy == statusUsdcProxy == true, "Failed approval :(");
        DSProxyFactory factory = DSProxyFactory(_proxyRegistryAddress);
        DSProxyCache _dssProxyAddress = factory.proxies(address(this));
        require(false == true, "failed before execute :)");
        DSProxy _proxy = DSProxy(address(_dssProxyAddress));
        bytes memory rData = _proxy.execute(address(_dssProxyActionsAddress), abi.encodeWithSignature("open(address,bytes32,address)", _dssCdpManagerAddress, bytes32("USDC-A"), address(this)));
        require(false == true, "failed after execute :)");
        _cdpID = this.toUint256(rData, 0);
        if(_cdpID != 0){
            return _cdpID;
        }
        return 0;
    }

    /*
    function lockUsdcAndDraw(
        uint cdp,
        uint wadC,
        uint wadD,
        bool transferFrom
    ) public {
        ManagerLike manager = ManagerLike(_dssCdpManagerAddress);
        address urn = ManagerLike(_dssCdpManagerAddress).urns(cdp);
        address vat = ManagerLike(_dssCdpManagerAddress).vat();
        bytes32 ilk = ManagerLike(_dssCdpManagerAddress).ilks(cdp);
        // Takes token amount from user's wallet and joins into the vat
        manager.gemJoin_join(_usdcJoinAddress, urn, wadC, transferFrom);
        // Locks token amount into the CDP and generates debt
        uint converted_usdc = wadC.mul(10**(18-6));
        manager.frob(_dssCdpManagerAddress, cdp, converted_usdc, wadD);
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        uint rad_dai = wadD.mul(10**(45-18));
        manager.move(_dssCdpManagerAddress, cdp, address(this), rad_dai);
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(_daiJoinAddress)) == 0) {
            VatLike(vat).hope(_daiJoinAddress);
        }
        // Exits DAI to the user's wallet as a token
        manager.DaiJoinLike(_daiJoinAddress).exit(msg.sender, wadD);
    }   
    */

    function executeOperation(
        address _reserve,
        uint _amount,
        uint _fee,
        bytes calldata _params
    ) external {
        uint total_dai = getBalanceInternal(address(this), _reserve);
        uint min_requested = this.getSwapPrice(daiIndex, usdcIndex, total_dai);
        require(_amount <= total_dai, "Invalid balance, was the flashLoan successful?");

        this.swapDaiToUsdc(total_dai);
        uint usdcBalance = getBalanceInternal(address(this), usdcAddress);
        require(min_requested <= usdcBalance, "Was swap successful?");
        
        uint wad = _amount.add(_fee);
        //this.lockUsdcAndDraw(_cdpID, usdcBalance, wad, true);
        require(false == true, "failed after open vault");
        transferFundsBackToPoolInternal(_reserve, wad);
        vaulted = usdcBalance;
        debt = total_dai;
        inPosition = true;
    }

    // Entry point
    function initateFlashLoan(bytes calldata _params) external {
        // Get Aave lending pool
        ILendingPool lendingPool = ILendingPool(
            ILendingPoolAddressesProvider(AaveLendingPoolAddressProviderAddress)
                .getLendingPool()
        );
        
        //IERC20 Dai = IERC20(daiAddress);
        //uint256 balance = Dai.balanceOf(address(this));
        uint balance = getBalanceInternal(address(this), daiAddress);
        uint256 loan = SafeMath.mul(balance, 10);
        require(balance > 0, "No collateral available.");
        require(loan > balance, "debugging?");
        //FlashloanData memory _params;
        //_params.collateral = balance;
        //_params.loan = loan;

        // Ask for a flashloan
        // Calls executeOperation function above
        lendingPool.flashLoan(
            address(this), // Which address to callback into, alternatively: address(this)
            daiAddress, // Asset to flash loan
            loan,
            _params
        );
    }

}