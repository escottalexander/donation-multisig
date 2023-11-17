// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {DonationMultisig} from "../src/DonationMultisig.sol";

contract DonationMultisigTest is Test {
    DonationMultisig public multisig;

    function setUp() public {

        multisig = new DonationMultisig();
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}


// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "forge-std/console2.sol";
// import "../src/PayoutUponCompletion.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// contract PayoutTest is Test {
//     address owner = address(12345);
//     PayoutUponCompletion public payout;
//     ERC20 public mockToken;

//     uint8 public initialProtocolTakeRate = uint8(10);

//     function setUp() public {
//         vm.startPrank(owner);
//         payout = new PayoutUponCompletion(uint8(10));
//         mockToken = new ERC20("MockDollar", "USDC");
//         payout.updateTokenAllowList(address(mockToken), true);
//         vm.stopPrank();
//     }

//     function testProtocolTakeRate() public {
//         assertEq(payout.protocolTakeRateBps(), uint8(10));
//     }

//     function testCreateTask(
//         string memory location,
//         address reviewer,
//         uint8 reviewerPercentage
//     ) public {
//         vm.assume(reviewer != address(0));
//         vm.assume(reviewerPercentage <= 100);

//         payout.createTask(location, reviewer, reviewerPercentage);
//         assertEq(payout.currentTaskIndex(), 1);
//     }

//     function testFundTask(
//         uint256 amount,
//         address token,
//         string memory location,
//         address reviewer,
//         uint8 reviewerPercentage
//     ) public {
//         vm.assume(amount > 0);

//         uint256 taskIndex = payout.currentTaskIndex();
//         testCreateTask(location, reviewer, reviewerPercentage);

//         _fundSpecificTask(taskIndex, amount, token);
//     }

//     function _fundSpecificTask(
//         uint256 taskIndex,
//         uint256 amount,
//         address token
//     ) public {
//         vm.assume(amount > 0);

//         if (token == address(0)) {
//             deal(address(this), amount);
//             payout.fundTask{value: amount}(taskIndex, amount, token);

//             assertEq(address(payout).balance, amount);
//         } else {
//             deal(address(mockToken), address(this), amount);
//             mockToken.approve(address(payout), amount);
//             payout.fundTask(taskIndex, amount, address(mockToken));

//             assertEq(mockToken.balanceOf(address(payout)), amount);
//         }
//     }

//     function testCreateAndFundTaskToken(
//         string memory taskLocation,
//         address reviewer,
//         uint8 reviewerPercentage,
//         uint256 amount
//     ) public returns (uint) {
//         deal(address(mockToken), address(this), amount);

//         vm.assume(reviewer != address(0));
//         vm.assume(reviewerPercentage <= 100 && amount > 0);

//         mockToken.approve(address(payout), amount);
//         uint taskIndex = payout.createAndFundTask(
//             taskLocation,
//             reviewer,
//             reviewerPercentage,
//             amount,
//             address(mockToken)
//         );

//         assertEq(mockToken.balanceOf(address(payout)), amount);
//         return taskIndex;
//     }

//     function testCreateAndFundTaskEther(
//         string memory taskLocation,
//         address reviewer,
//         uint8 reviewerPercentage,
//         uint256 amount
//     ) public returns (uint) {
//         deal(address(this), amount);
//         vm.assume(reviewer != address(0));
//         vm.assume(reviewerPercentage <= 100 && amount > 0);

//         uint taskIdx = payout.createAndFundTask{value: amount}(
//             taskLocation,
//             reviewer,
//             reviewerPercentage,
//             amount,
//             address(0)
//         );

//         assertEq(address(payout).balance, amount);
//         return taskIdx;
//     }

//     function testSubmitWork(string memory location, address reviewer) public {
//         uint256 taskIndex = payout.currentTaskIndex();
//         testCreateTask(location, reviewer, 10);

//         payout.submitWork(taskIndex, location);
//     }

//     function testCancelTaskNotReviewerBeforeUnlock(
//         string memory location,
//         address reviewer
//     ) public {
//         vm.assume(reviewer != address(0) && reviewer != address(this));
//         uint256 taskIndex = payout.currentTaskIndex();
//         address[] memory funders;
//         address[] memory tokens;
//         testCreateTask(location, reviewer, 10);
//         vm.expectRevert(PayoutUponCompletion.NotAuthorized.selector);
//         payout.cancelTask(taskIndex, funders, tokens);
//     }

//     function testCancelTaskNotReviewerAfterUnlock(
//         string memory location,
//         address reviewer
//     ) public {
//         vm.assume(reviewer != address(0) && reviewer != address(this));
//         uint256 taskIndex = payout.currentTaskIndex();
//         address[] memory funders;
//         address[] memory tokens;
//         testCreateTask(location, reviewer, 10);
//         skip(payout.unlockPeriod());
//         payout.cancelTask(taskIndex, funders, tokens);
//         PayoutUponCompletion.Task memory task = payout.getTask(taskIndex);
//         assertEq(task.canceled, true);
//     }

//     function testCancelTaskReviewerBeforeUnlock(
//         string memory location,
//         address reviewer
//     ) public {
//         vm.assume(reviewer != address(0) && reviewer != address(payout));
//         uint256 taskIndex = payout.currentTaskIndex();
//         address[] memory emptyArray;

//         skip(payout.unlockPeriod());

//         testCreateTask(location, reviewer, 10);

//         vm.startPrank(reviewer);
//         payout.cancelTask(taskIndex, emptyArray, emptyArray);
//         PayoutUponCompletion.Task memory task = payout.getTask(taskIndex);
//         assertEq(task.canceled, true);
//     }

//     function testFinalizeTask(
//         string memory location,
//         address reviewer,
//         address approvedWorker
//     ) public {
//         vm.assume(reviewer != address(0) && reviewer != address(payout));
//         vm.assume(approvedWorker != address(0));
//         uint256 taskIndex = payout.currentTaskIndex();
//         skip(payout.unlockPeriod());

//         testCreateTask(location, reviewer, 10);
//         vm.startPrank(reviewer);
//         payout.approveTask(taskIndex, approvedWorker);
//         address[] memory funding;
//         payout.finalizeTask(taskIndex, funding);
//     }

//     function testApproveTask(
//         address approvedWorker,
//         address reviewer,
//         string memory location
//     ) public {
//         vm.assume(reviewer != address(0) && reviewer != address(payout));
//         vm.assume(approvedWorker != address(0));
//         uint256 taskIndex = payout.currentTaskIndex();
//         skip(payout.unlockPeriod());

//         testCreateTask(location, reviewer, 10);
//         vm.startPrank(reviewer);
//         payout.approveTask(taskIndex, approvedWorker);
//     }

//     function testDivyUp(
//         uint8 reviewerPercentage,
//         uint16 protocolTakeRate,
//         uint256 amount
//     ) public {
//         vm.assume(reviewerPercentage <= 100 && reviewerPercentage >= 0);
//         vm.assume(protocolTakeRate <= payout.maxProtocolTakeRateBps());
//         // Setting a cap on the amount so we don't run into overflow errors with the simple math later in the test
//         vm.assume(amount > 0 && amount < 1e30);
//         address reviewer = address(1001);
//         address approvedWorker = address(1010);
//         vm.startPrank(owner);
//         payout.adjustTakeRate(protocolTakeRate);
//         vm.stopPrank();
//         uint taskIndex = testCreateAndFundTaskEther(
//             "location",
//             reviewer,
//             reviewerPercentage,
//             amount
//         );

//         vm.startPrank(reviewer);
//         payout.approveTask(taskIndex, approvedWorker);
//         address[] memory funding = new address[](1);
//         funding[0] = address(0);
//         payout.finalizeTask(taskIndex, funding);

//         uint256 reviewerBalance = payout.getWithdrawableBalance(address(0));
//         vm.stopPrank();

//         vm.startPrank(approvedWorker);
//         uint256 workerBalance = payout.getWithdrawableBalance(address(0));
//         vm.stopPrank();

//         uint protocolBalance = address(payout).balance -
//             workerBalance -
//             reviewerBalance;

//         // Prove the amounts with simple math since we don't need to fear an overflow
//         uint reviewerComparison = ((amount - protocolBalance) *
//             reviewerPercentage) / 100;
//         uint workerComparison = amount - reviewerBalance - protocolBalance;
//         uint protocolComparison = (amount * protocolTakeRate) / 10000;

//         assertEq(reviewerBalance, reviewerComparison);
//         assertEq(workerBalance, workerComparison);
//         assertEq(protocolBalance, protocolComparison);
//     }

//     function testFundingFlowEther(
//         address approvedWorker,
//         address reviewer,
//         uint8 reviewerPercentage,
//         uint16 protocolTakeRate,
//         string memory taskLocation,
//         uint256 amount
//     ) public {
//         vm.assume(reviewer != address(0) && reviewer != address(this));
//         vm.assume(reviewerPercentage <= 100 && reviewerPercentage >= 0);
//         vm.assume(approvedWorker != address(0));
//         vm.assume(amount > 0);
//         vm.assume(protocolTakeRate <= payout.maxProtocolTakeRateBps());
//         assumeNotPrecompile(approvedWorker);
//         assumePayable(approvedWorker);
//         assumeNotPrecompile(reviewer);
//         assumePayable(reviewer);

//         vm.startPrank(owner);
//         payout.adjustTakeRate(protocolTakeRate);
//         vm.stopPrank();
//         uint256 taskIndex = payout.currentTaskIndex();

//         testCreateAndFundTaskEther(
//             taskLocation,
//             reviewer,
//             reviewerPercentage,
//             amount
//         );
//         vm.startPrank(reviewer);
//         payout.approveTask(taskIndex, approvedWorker);
//         address[] memory funding = new address[](1);
//         funding[0] = address(0);
//         payout.finalizeTask(taskIndex, funding);

//         // Reviewer Withdraw
//         uint256 reviewerBalance = payout.getWithdrawableBalance(address(0));
//         uint beforeReviewerContractBalance = address(payout).balance;
//         payout.withdraw(reviewerBalance, address(0));
//         uint afterReviewerContractBalance = address(payout).balance;
//         assertEq(
//             reviewerBalance,
//             beforeReviewerContractBalance - afterReviewerContractBalance
//         );
//         vm.stopPrank();

//         // Worker Withdraw
//         vm.startPrank(approvedWorker);
//         uint256 workerBalance = payout.getWithdrawableBalance(address(0));
//         uint beforeWorkerContractBalance = address(payout).balance;
//         payout.withdraw(workerBalance, address(0));
//         uint afterWorkerContractBalance = address(payout).balance;
//         assertEq(
//             workerBalance,
//             beforeWorkerContractBalance - afterWorkerContractBalance
//         );
//         vm.stopPrank();

//         // Owner withdraws tokens
//         vm.startPrank(owner);
//         payout.withdrawProtocolTokens(address(0));
//         // Contract should be empty now
//         uint contractBalance = address(payout).balance;
//         assertEq(contractBalance, 0);
//     }

//     function testFundingFlowERC20(
//         address approvedWorker,
//         address reviewer,
//         uint8 reviewerPercentage,
//         uint16 protocolTakeRate,
//         string memory taskLocation,
//         uint256 amount
//     ) public {
//         vm.assume(reviewer != address(0) && reviewer != address(this));
//         vm.assume(reviewerPercentage <= 100 && reviewerPercentage >= 0);
//         vm.assume(approvedWorker != address(0));
//         vm.assume(amount > 0);
//         vm.assume(protocolTakeRate <= payout.maxProtocolTakeRateBps());
//         assumeNotPrecompile(approvedWorker);
//         assumePayable(approvedWorker);
//         assumeNotPrecompile(reviewer);
//         assumePayable(reviewer);

//         vm.startPrank(owner);
//         payout.adjustTakeRate(protocolTakeRate);
//         vm.stopPrank();
//         uint256 taskIndex = payout.currentTaskIndex();

//         testCreateAndFundTaskToken(
//             taskLocation,
//             reviewer,
//             reviewerPercentage,
//             amount
//         );
//         vm.startPrank(reviewer);
//         payout.approveTask(taskIndex, approvedWorker);
//         address[] memory funding = new address[](1);
//         funding[0] = address(mockToken);
//         payout.finalizeTask(taskIndex, funding);

//         // Reviewer Withdraw
//         uint256 reviewerBalance = payout.getWithdrawableBalance(
//             address(mockToken)
//         );
//         uint beforeReviewerContractBalance = mockToken.balanceOf(
//             address(payout)
//         );
//         payout.withdraw(reviewerBalance, address(mockToken));
//         uint afterReviewerContractBalance = mockToken.balanceOf(
//             address(payout)
//         );
//         assertEq(
//             reviewerBalance,
//             beforeReviewerContractBalance - afterReviewerContractBalance
//         );
//         vm.stopPrank();

//         // Worker Withdraw
//         vm.startPrank(approvedWorker);
//         uint256 workerBalance = payout.getWithdrawableBalance(
//             address(mockToken)
//         );
//         uint beforeWorkerContractBalance = mockToken.balanceOf(address(payout));
//         payout.withdraw(workerBalance, address(mockToken));
//         uint afterWorkerContractBalance = mockToken.balanceOf(address(payout));
//         assertEq(
//             workerBalance,
//             beforeWorkerContractBalance - afterWorkerContractBalance
//         );
//         vm.stopPrank();

//         // Owner withdraws tokens
//         vm.startPrank(owner);
//         payout.withdrawProtocolTokens(address(mockToken));
//         // Contract should be empty now
//         uint contractBalance = mockToken.balanceOf(address(payout));
//         assertEq(contractBalance, 0);
//     }

//     function _sortAddresses(
//         address[] memory addresses
//     ) public pure returns (address[] memory) {
//         uint256 n = addresses.length;

//         for (uint256 i = 0; i < n - 1; i++) {
//             for (uint256 j = 0; j < n - i - 1; j++) {
//                 if (addresses[j] > addresses[j + 1]) {
//                     // Swap addresses[j] and addresses[j+1]
//                     address temp = addresses[j];
//                     addresses[j] = addresses[j + 1];
//                     addresses[j + 1] = temp;
//                 }
//             }
//         }
//         return addresses;
//     }

//     function testGasGriefingPoC() public {
//         address reviewer = address(0x110);
//         uint256 amount = 1e18;
//         testCreateTask("testing", reviewer, 10);

//         ERC20[] memory tokens = new ERC20[](1000);
//         address[] memory funding = new address[](1000);
//         for (uint256 i; i < 1000; ) {
//             tokens[i] = new ERC20("Junk", "JNK");
//             vm.startPrank(owner);
//             payout.updateTokenAllowList(address(tokens[i]), true);
//             vm.stopPrank();
//             deal(address(tokens[i]), address(this), amount);
//             tokens[i].approve(address(payout), amount);
//             payout.fundTask(0, amount, address(tokens[i]));
//             funding[i] = address(tokens[i]);
//             unchecked {
//                 ++i;
//             }
//         }
//         address[] memory sorted = _sortAddresses(funding);
//         vm.startPrank(reviewer);
//         payout.approveTask(0, address(111));
//         payout.finalizeTask(0, sorted);
//     }

//     function testUpdateTokenAllowList(address token) public {
//         vm.startPrank(owner);
//         payout.updateTokenAllowList(token, true);
//         vm.stopPrank();
//         bool isAllowed = payout.isTokenAllowed(token);
//         assertEq(isAllowed, true);
//     }

//     function testGetTaskFundingTally(uint amountOne, uint amountTwo) public {
//         vm.assume(amountOne > 0 && amountOne < type(uint256).max / 2);
//         vm.assume(amountTwo > 0 && amountTwo < type(uint256).max / 2);
//         address reviewer = address(11);
//         uint8 reviewerPercentage;
//         address otherUser = address(1001);
//         // Creating two tasks that will be funded the same so we can test finalize and cancel
//         uint taskIndex = testCreateAndFundTaskEther(
//             "anything",
//             reviewer,
//             reviewerPercentage,
//             amountOne
//         );
//         deal(address(mockToken), address(otherUser), amountTwo);
//         testUpdateTokenAllowList(address(mockToken));
//         vm.startPrank(otherUser);
//         mockToken.approve(address(payout), amountTwo);
//         _fundSpecificTask(taskIndex, amountTwo, address(mockToken));

//         address[] memory fullFunding = new address[](2);
//         fullFunding[0] = address(0);
//         fullFunding[1] = address(mockToken);

//         (address[] memory tokens, uint[] memory amounts, bool isAllTokens, bool isProperlyFormatted) = payout
//             .getTaskFunding(taskIndex, fullFunding);
//         assertEq(tokens[0], address(0));
//         assertEq(tokens[1], address(mockToken));
//         assertEq(amounts[0], amountOne);
//         assertEq(amounts[1], amountTwo);
//         assertEq(isAllTokens, true);
//         assertEq(isProperlyFormatted, true);
//     }

//         function testGetTaskFundingTallyIncompleteData(uint amountOne, uint amountTwo) public {
//         vm.assume(amountOne > 0 && amountOne < type(uint256).max / 2);
//         vm.assume(amountTwo > 0 && amountTwo < type(uint256).max / 2);
//         address reviewer = address(11);
//         uint8 reviewerPercentage;
//         address otherUser = address(1001);
//         // Creating two tasks that will be funded the same so we can test finalize and cancel
//         uint taskIndex = testCreateAndFundTaskEther(
//             "anything",
//             reviewer,
//             reviewerPercentage,
//             amountOne
//         );
//         deal(address(mockToken), address(otherUser), amountTwo);
//         testUpdateTokenAllowList(address(mockToken));
//         vm.startPrank(otherUser);
//         mockToken.approve(address(payout), amountTwo);
//         _fundSpecificTask(taskIndex, amountTwo, address(mockToken));

//         // Defining an array with only ERC20 - remember, we funded with ETH to start
//         address[] memory partialFunding = new address[](1);
//         partialFunding[0] = address(mockToken);
//         // Adding ETH to this one
//         address[] memory wrongTypeFunding = new address[](2);
//         address[] memory wrongOrderFunding = new address[](2);
//         wrongOrderFunding[0] = address(mockToken);
//         wrongOrderFunding[1] = address(0);

//         (,, bool isAllTokens1, bool isProperlyFormatted1) = payout.getTaskFunding(taskIndex, partialFunding);
//         assertEq(isAllTokens1, false);
//         assertEq(isProperlyFormatted1, true);

//         (,, bool isAllTokens2, bool isProperlyFormatted2) = payout.getTaskFunding(taskIndex, wrongTypeFunding);
//         // This can be true even if duplicate tokens are sent and quantities match
//         assertEq(isAllTokens2, amountOne == amountTwo);
//         assertEq(isProperlyFormatted2, false);

//         (,, bool isAllTokens3, bool isProperlyFormatted3) = payout.getTaskFunding(taskIndex, wrongOrderFunding);
//         assertEq(isAllTokens3, true);
//         assertEq(isProperlyFormatted3, false);
//     }

//     function testFinalizeTaskTally(uint amount) public {
//         vm.assume(amount > 0 && amount < type(uint256).max / 2);
//         address reviewer = address(11);
//         uint8 reviewerPercentage;
//         address otherUser = address(1001);
//         uint taskIndex = testCreateAndFundTaskEther(
//             "anything",
//             reviewer,
//             reviewerPercentage,
//             amount
//         );
//         deal(address(mockToken), address(otherUser), amount);
//         testUpdateTokenAllowList(address(mockToken));
//         vm.startPrank(otherUser);
//         mockToken.approve(address(payout), amount);
//         _fundSpecificTask(taskIndex, amount, address(mockToken));

//         address[] memory partialFunding = new address[](1);
//         partialFunding[0] = address(mockToken);
//         // new address[](2) creates an array with [address(0), address(0)]
//         address[] memory wrongTypeFunding = new address[](2);
//         address[] memory wrongOrderFunding = new address[](2);
//         wrongOrderFunding[0] = address(mockToken);
//         address[] memory fullFunding = new address[](2);
//         fullFunding[1] = address(mockToken);

//         vm.startPrank(address(reviewer));
//         // Task One to be finalized
//         address approvedWorker = address(1111);
//         payout.approveTask(taskIndex, approvedWorker);
//         // Should fail because tally won't match
//         vm.expectRevert(PayoutUponCompletion.InvalidAmount.selector);
//         payout.finalizeTask(taskIndex, partialFunding);
//         // Should fail because though token amounts are correct, duplicate tokens are given
//         vm.expectRevert(
//             PayoutUponCompletion.CalldataImproperlyFormatted.selector
//         );
//         payout.finalizeTask(taskIndex, wrongTypeFunding);
//         // Should fail because though token type are correct, they are not in ascending order
//         vm.expectRevert(
//             PayoutUponCompletion.CalldataImproperlyFormatted.selector
//         );
//         payout.finalizeTask(taskIndex, wrongOrderFunding);
//         // Should succeed
//         payout.finalizeTask(taskIndex, fullFunding);

//         PayoutUponCompletion.Task memory task = payout.getTask(taskIndex);
//         assertEq(task.complete, true);
//     }

//     function testCancelTaskTally(uint amount) public {
//         vm.assume(amount > 0 && amount < type(uint256).max / 2);
//         address reviewer = address(11);
//         uint8 reviewerPercentage;
//         address userOne = address(1001);
//         address userTwo = address(1002);
//         // Creating two tasks that will be funded the same so we can test finalize and cancel
//         deal(userOne, amount);
//         vm.startPrank(userOne);
//         uint taskIndex = testCreateAndFundTaskEther(
//             "anything",
//             reviewer,
//             reviewerPercentage,
//             amount
//         );
//         vm.stopPrank();
//         deal(address(mockToken), userTwo, amount);
//         testUpdateTokenAllowList(address(mockToken));
//         vm.startPrank(userTwo);
//         mockToken.approve(address(payout), amount);
//         _fundSpecificTask(taskIndex, amount, address(mockToken));
//         vm.stopPrank();
//         address[] memory partialFunders = new address[](1);
//         partialFunders[0] = userOne;
//         address[] memory partialTokens = new address[](1);
//         partialTokens[0] = address(0);
//         address[] memory wrongTypeFunders = new address[](2);
//         wrongTypeFunders[0] = userOne;
//         wrongTypeFunders[1] = userTwo;
//         address[] memory wrongTypeTokens = new address[](2);
//         address[] memory duplicatedFunders = new address[](2);
//         duplicatedFunders[0] = userOne;
//         duplicatedFunders[1] = userOne;
//         address[] memory duplicatedTokens = new address[](2);
//         address[] memory fullFunders = new address[](2);
//         fullFunders[0] = userOne;
//         fullFunders[1] = userTwo;
//         address[] memory fullTokens = new address[](2);
//         fullTokens[0] = address(0);
//         fullTokens[1] = address(mockToken);

//         vm.startPrank(address(reviewer));
//         // Should fail because tally won't match
//         vm.expectRevert(PayoutUponCompletion.InvalidAmount.selector);
//         payout.cancelTask(taskIndex, partialFunders, partialTokens);
//         // Should fail because user token pair is duplicated
//         vm.expectRevert(PayoutUponCompletion.InvalidAmount.selector);
//         payout.cancelTask(taskIndex, duplicatedFunders, duplicatedTokens);
//         // Should fail because tally won't match tokens
//         vm.expectRevert(PayoutUponCompletion.InvalidAmount.selector);
//         payout.cancelTask(taskIndex, wrongTypeFunders, wrongTypeTokens);
//         // Should fail because array lengths don't match
//         vm.expectRevert(
//             PayoutUponCompletion.CalldataImproperlyFormatted.selector
//         );
//         payout.cancelTask(taskIndex, partialFunders, wrongTypeTokens);

//         payout.cancelTask(taskIndex, fullFunders, fullTokens);

//         PayoutUponCompletion.Task memory task = payout.getTask(taskIndex);
//         assertEq(task.canceled, true);
//     }

//     // TODO test cases
//     // Create multiple tasks with various funding
//     // Negative test cases for all
//     // Update token allow list
//     // permanentlyLowerMaxTakeRate
//     // Withdraw protocol tokens
// }
