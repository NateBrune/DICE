pragma solidity >=0.5.0;

import "@studydefi/money-legos/maker/contracts/DssProxyActionsBase.sol";

// Referenced from
// https://github.com/makerdao/dss-proxy-actions/blob/968b5030523af74d786520a9a664b31fa811c05c/src/DssProxyActions.sol#L583

contract VaultManager is DssProxyActionsBase {
    /*
    function openUsdcVault(
        address manager,
        address jug,
        address usdcJoin,
        address daiJoin,
        uint wadD,
        uint amount
    ) public payable {
        // Opens USDC-A CDP
        bytes32 ilk = bytes32("USDC-A");
        
        uint cdp = open(manager, ilk, address(this));
        require(false == true, "Got passed open :)");
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        // Joins USDC into the vat
        require(false == true, "Got passed variables");
        gemJoin_join(usdcJoin, urn, amount, true);
        require(false == true, "Got passed join");
        // Locks USDC amount into the CDP and generates debt
        frob(manager, cdp, toInt(msg.value), _getDrawDart(vat, jug, urn, ilk, wadD));
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), toRad(wadD));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }

        // Exits DAI to the user's wallet as a token
        DaiJoinLike(daiJoin).exit(msg.sender, wadD);
    }
    */

    uint public _cdp = 0;
    function openUsdcVault(address manager, address usr) public returns (uint) {
        bytes32 ilk = bytes32("USDC-A");
        if(_cdp == 0){
            _cdp = open(manager, ilk, usr);
            return _cdp;
        }
        return 0;
    }

    function lockUsdcAndDraw(
        address manager,
        address jug,
        address gemJoin,
        address daiJoin,
        uint cdp,
        uint wadC,
        uint wadD,
        bool transferFrom
    ) public {
        address urn = ManagerLike(manager).urns(cdp);
        address vat = ManagerLike(manager).vat();
        bytes32 ilk = ManagerLike(manager).ilks(cdp);
        // Takes token amount from user's wallet and joins into the vat
        gemJoin_join(gemJoin, urn, wadC, transferFrom);
        // Locks token amount into the CDP and generates debt
        frob(manager, cdp, toInt(convertTo18(gemJoin, wadC)), _getDrawDart(vat, jug, urn, ilk, wadD));
        // Moves the DAI amount (balance in the vat in rad) to proxy's address
        move(manager, cdp, address(this), toRad(wadD));
        // Allows adapter to access to proxy's DAI balance in the vat
        if (VatLike(vat).can(address(this), address(daiJoin)) == 0) {
            VatLike(vat).hope(daiJoin);
        }
        // Exits DAI to the user's wallet as a token
        DaiJoinLike(daiJoin).exit(msg.sender, wadD);
    }
}
