// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniversalVerifier {
    function isProofVerified(address user, uint64 requestId) external view returns (bool);
}

contract KYCDeFiLayer {
    IERC20 public immutable stableToken;
    IUniversalVerifier public immutable verifier;

    uint64 public immutable BASIC_KYC_REQUEST_ID;
    uint64 public immutable ADVANCED_KYC_REQUEST_ID;

    uint256 public constant DAILY_LIMIT = 1000 * 10 ** 18;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public lastDepositTimestamp;
    mapping(address => uint256) public dailyDeposited;

    constructor(
        address _token,
        address _verifier,
        uint64 _basicKycRequestId,
        uint64 _advancedKycRequestId
    ) {
        stableToken = IERC20(_token);
        verifier = IUniversalVerifier(_verifier);
        BASIC_KYC_REQUEST_ID = _basicKycRequestId;
        ADVANCED_KYC_REQUEST_ID = _advancedKycRequestId;
    }

    function deposit(uint256 amount) external {
        require(_hasKYC(msg.sender), "KYC required");

        if (!_isAdvancedKYC(msg.sender)) {
            if (block.timestamp - lastDepositTimestamp[msg.sender] > 1 days) {
                dailyDeposited[msg.sender] = 0;
                lastDepositTimestamp[msg.sender] = block.timestamp;
            }
            require(dailyDeposited[msg.sender] + amount <= DAILY_LIMIT, "Daily limit exceeded");
            dailyDeposited[msg.sender] += amount;
        }

        require(stableToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(_hasKYC(msg.sender), "KYC required");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        require(stableToken.transfer(msg.sender, amount), "Withdraw failed");
    }

    /// Универсальный метод взаимодействия с DeFi-протоколами
    function callDeFi(address target, bytes calldata data) external {
        require(_hasKYC(msg.sender), "KYC required");
        (bool success, bytes memory returnData) = target.call(data);
        require(success, "DeFi call failed");
    }

    function _hasKYC(address user) internal view returns (bool) {
        return
            verifier.isProofVerified(user, BASIC_KYC_REQUEST_ID) ||
            verifier.isProofVerified(user, ADVANCED_KYC_REQUEST_ID);
    }

    function _isAdvancedKYC(address user) internal view returns (bool) {
        return verifier.isProofVerified(user, ADVANCED_KYC_REQUEST_ID);
    }
}