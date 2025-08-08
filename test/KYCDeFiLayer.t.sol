// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KYCDeFiLayer.sol";

contract MockToken is IERC20 {
    string public constant NAME = "Mock Stablecoin";
    string public constant SYMBOL = "MUSD";
    uint8 public constant DECIMALS = 18;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    function totalSupply() public pure override returns (uint256) {
        return 1_000_000 ether;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Not approved");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }

    function mint(address to, uint256 amount) public {
        balanceOf[to] += amount;
    }
}

contract MockVerifier is IUniversalVerifier {
    mapping(address => bool) public basic;
    mapping(address => bool) public advanced;

    function setBasic(address user, bool ok) external {
        basic[user] = ok;
    }

    function setAdvanced(address user, bool ok) external {
        advanced[user] = ok;
    }

    function isProofVerified(address user, uint64 requestId) external view override returns (bool) {
        if (requestId == 1) return basic[user];
        if (requestId == 2) return advanced[user];
        return false;
    }
}

contract KYCDeFiLayerTest is Test {
    KYCDeFiLayer public layer;
    MockToken public token;
    MockVerifier public verifier;

    address public user = address(1);

    function setUp() public {
        token = new MockToken();
        verifier = new MockVerifier();
        layer = new KYCDeFiLayer(address(token), address(verifier), 1, 2);
        token.mint(user, 5000 ether);
    }

    function test_RevertWithoutKYC() public {
        vm.startPrank(user);
        token.approve(address(layer), 1000 ether);
        vm.expectRevert(bytes("KYC required"));
        layer.deposit(1000 ether);
        vm.stopPrank();
    }

    function test_RevertWithoutApprove() public {
        verifier.setAdvanced(user, true);
        vm.startPrank(user);
        vm.expectRevert(); // Transfer failed
        layer.deposit(1000 ether);
        vm.stopPrank();
    }

    function test_RevertWithdrawWithoutKYC() public {
        vm.startPrank(user);
        vm.expectRevert(bytes("KYC required"));
        layer.withdraw(100 ether);
        vm.stopPrank();
    }

    function test_RevertWithdrawWithoutBalance() public {
        verifier.setAdvanced(user, true);
        vm.startPrank(user);
        vm.expectRevert(bytes("Insufficient balance"));
        layer.withdraw(100 ether);
        vm.stopPrank();
    }

    function test_RevertBasicKYCLimitExceeded() public {
        verifier.setBasic(user, true);
        vm.startPrank(user);
        token.approve(address(layer), 2000 ether);
        layer.deposit(1000 ether); // ok
        vm.expectRevert(bytes("Daily limit exceeded"));
        layer.deposit(1 ether); // too much
        vm.stopPrank();
    }

    function test_BasicKYCLimitOK() public {
        verifier.setBasic(user, true);
        vm.startPrank(user);
        token.approve(address(layer), 1000 ether);
        layer.deposit(1000 ether);
        assertEq(layer.balances(user), 1000 ether);
        vm.stopPrank();
    }

    function test_AdvancedKYCLimitUnlimited() public {
        verifier.setAdvanced(user, true);
        vm.startPrank(user);
        token.approve(address(layer), 3000 ether);
        layer.deposit(3000 ether);
        assertEq(layer.balances(user), 3000 ether);
        vm.stopPrank();
    }

    function test_WithdrawAfterDeposit() public {
        verifier.setAdvanced(user, true);
        vm.startPrank(user);
        token.approve(address(layer), 1000 ether);
        layer.deposit(1000 ether);
        layer.withdraw(400 ether);
        assertEq(layer.balances(user), 600 ether);
        vm.stopPrank();
    }

    function test_ResetDailyLimitAfterOneDay() public {
        verifier.setBasic(user, true);
        vm.startPrank(user);
        token.approve(address(layer), 2000 ether);
        layer.deposit(1000 ether); // full limit
        vm.warp(block.timestamp + 1 days + 1);
        layer.deposit(500 ether); // should be allowed after reset
        assertEq(layer.balances(user), 1500 ether);
        vm.stopPrank();
    }

    function test_InitOk() public view {
        assert(address(layer.verifier()) != address(0));
        assert(address(layer.stableToken()) != address(0));
        assert(layer.BASIC_KYC_REQUEST_ID() == 1);
        assert(layer.ADVANCED_KYC_REQUEST_ID() == 2);
    }
    function test_CallDeFiWithKYC() public {
    verifier.setAdvanced(user, true);
    MockDeFi defi = new MockDeFi();

    vm.startPrank(user);
    layer.callDeFi(address(defi), abi.encodeWithSignature("doSomething()"));
    vm.stopPrank();

    assertTrue(defi.called(), "DeFi call should succeed");
    }

    function test_CallDeFiWithoutKYC() public {
    MockDeFi defi = new MockDeFi();

    vm.startPrank(user);
    vm.expectRevert(bytes("KYC required"));
    layer.callDeFi(address(defi), abi.encodeWithSignature("doSomething()"));
    vm.stopPrank();
    }
}

contract MockDeFi {
    bool public called;

    function doSomething() external {
        called = true;
    }
}

