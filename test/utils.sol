pragma solidity >=0.5.0;

contract CurveFiManagerLike {
  function getSwapPrice(int128 from, int128 to, uint256 amount) external returns (uint);
  function swapDaiToUsdc(uint256 amount) external;
  function getApproval() external returns (bool);
  function buildProxy() external returns (address);
  function toUint256(bytes calldata _bytes, uint256 _start) external pure returns (uint256);
  function openVault() external returns (uint);
  function executeOperation(address _reserve, uint _amount, uint _fee, bytes calldata _params) external;
  function initateFlashLoan(bytes calldata _params) external;
}