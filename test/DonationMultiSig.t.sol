// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Test, console2 } from "forge-std/Test.sol";
import { DonationMultiSig } from "../src/DonationMultiSig.sol";
import { MockToken } from "../src/MockToken.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DonationMultiSigTest is Test {
    DonationMultiSig public multisig;
    address firstSigner = address(1);
    address secondSigner = address(2);
    address thirdSigner = address(3);
    ERC20 public mockToken;

    function setUp() public {
        mockToken = new MockToken();
        address[] memory contributors = new address[](3);
        contributors[0] = firstSigner;
        contributors[1] = secondSigner;
        contributors[2] = thirdSigner;
        uint32[] memory weights = new uint32[](3);
        weights[0] = 10;
        weights[1] = 10;
        weights[2] = 10;
        multisig = new DonationMultiSig(contributors, weights);
    }

    function test_proposeAddContributor() public {
        address contributor = address(123);
        uint32 weight = 10;
        vm.startPrank(firstSigner);
        multisig.proposeAddContributor(contributor, weight);
        bool exists;
        uint32 propWeight;
        uint8 approvalCount;
        (exists, propWeight, approvalCount) = multisig.addProposals(contributor);
        assertEq(approvalCount, 0);
        assertEq(exists, true);
        assertEq(propWeight, weight);
    }

    function testFuzz_proposeAddContributor(address contributor, uint32 weight) public {
        vm.assume(weight > 0);
        vm.assume(multisig.isContributor(contributor) == false);
        vm.startPrank(firstSigner);
        multisig.proposeAddContributor(contributor, weight);
        bool exists;
        uint32 propWeight;
        uint8 approvalCount;
        (exists, propWeight, approvalCount) = multisig.addProposals(contributor);
        assertEq(approvalCount, 0);
        assertEq(exists, true);
        assertEq(propWeight, weight);
    }

    function test_proposeAddContributorNotZeroWeight() public {
        address contributor = address(123);
        uint32 weight = 0;
        vm.startPrank(firstSigner);
        vm.expectRevert(abi.encodeWithSelector(DonationMultiSig.NewContributorCannotHaveZeroWeight.selector, contributor));
        multisig.proposeAddContributor(contributor, weight);
    }

    function testFuzz_proposeAddContributorNotAlreadyProposed(address contributor, uint32 weight) public {
        vm.assume(weight > 0);
        vm.assume(multisig.isContributor(contributor) == false);
        vm.startPrank(firstSigner);
        multisig.proposeAddContributor(contributor, weight);
        vm.expectRevert(abi.encodeWithSelector(DonationMultiSig.AlreadyProposed.selector, contributor));
        multisig.proposeAddContributor(contributor, weight);
    }

    function testFuzz_proposeAddContributorNotContributor(address attempter) public {
        vm.assume(multisig.isContributor(attempter) == false);
        address contributor = address(123);
        uint32 weight = 10;
        vm.startPrank(attempter);
        vm.expectRevert(DonationMultiSig.OnlyContributor.selector);
        multisig.proposeAddContributor(contributor, weight);
    }

    function test_approveAddContributor() public {
        address contributor = address(123);
        uint32 weight = 10;
        vm.startPrank(firstSigner);
        // Approval is implied by proposer
        multisig.proposeAddContributor(contributor, weight);
        uint8 approvalCount;
        (,,approvalCount) = multisig.addProposals(contributor);
        assertEq(approvalCount, 0);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveAddContributor(contributor);
        uint8 approvalCount2;
        (,,approvalCount2) = multisig.addProposals(contributor);
        assertEq(approvalCount2, 1);
        vm.stopPrank();
        vm.startPrank(thirdSigner);
        multisig.approveAddContributor(contributor);
        uint8 approvalCount3;
        (,,approvalCount3) = multisig.addProposals(contributor);
        assertEq(approvalCount3, 2);
        multisig.addContributor(contributor);
        assertEq(multisig.isContributor(contributor), true);
    }

    function testFuzz_approveAddContributor(address contributor, uint32 weight) public {
        vm.assume(weight > 0);
        vm.assume(multisig.isContributor(contributor) == false);
        vm.startPrank(firstSigner);
        // Approval is implied by proposer
        multisig.proposeAddContributor(contributor, weight);
        uint8 approvalCount;
        (,,approvalCount) = multisig.addProposals(contributor);
        assertEq(approvalCount, 0);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveAddContributor(contributor);
        uint8 approvalCount2;
        (,,approvalCount2) = multisig.addProposals(contributor);
        assertEq(approvalCount2, 1);
        vm.stopPrank();
        vm.startPrank(thirdSigner);
        multisig.approveAddContributor(contributor);
        uint8 approvalCount3;
        (,,approvalCount3) = multisig.addProposals(contributor);
        assertEq(approvalCount3, 2);
        multisig.addContributor(contributor);
        assertEq(multisig.isContributor(contributor), true);
    }

    function testFuzz_approveAddContributorNotAlreadyApproved(address contributor, uint32 weight) public {
        vm.assume(weight > 0);
        vm.assume(multisig.isContributor(contributor) == false);
        vm.startPrank(firstSigner);
        multisig.proposeAddContributor(contributor, weight);
        vm.expectRevert(abi.encodeWithSelector(DonationMultiSig.AlreadyApproved.selector, contributor, firstSigner));
        multisig.approveAddContributor(contributor);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveAddContributor(contributor);
        vm.expectRevert(abi.encodeWithSelector(DonationMultiSig.AlreadyApproved.selector, contributor, secondSigner));
        multisig.approveAddContributor(contributor);
        vm.stopPrank();
        assertEq(multisig.isContributor(contributor), false);
    }

    function test_addContributor() public {
        address contributor = address(123);
        uint32 weight = 10;
        vm.startPrank(firstSigner);
        // Approval is implied by proposer
        multisig.proposeAddContributor(contributor, weight);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveAddContributor(contributor);
        vm.stopPrank();
        vm.startPrank(thirdSigner);
        multisig.approveAddContributor(contributor);
        multisig.addContributor(contributor);
        assertEq(multisig.isContributor(contributor), true);
    }

    function testFuzz_addContributor(address contributor, uint32 weight) public {
        vm.assume(weight > 0);
        vm.assume(multisig.isContributor(contributor) == false);
        vm.startPrank(firstSigner);
        // Approval is implied by proposer
        multisig.proposeAddContributor(contributor, weight);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveAddContributor(contributor);
        vm.stopPrank();
        vm.startPrank(thirdSigner);
        multisig.approveAddContributor(contributor);
        multisig.addContributor(contributor);
        assertEq(multisig.isContributor(contributor), true);
    }

    function testFuzz_addContributorNotEnoughApprovals(address contributor, uint32 weight) public {
        vm.assume(weight > 0);
        vm.assume(multisig.isContributor(contributor) == false);
        vm.startPrank(firstSigner);
        // Approval is implied by proposer
        multisig.proposeAddContributor(contributor, weight);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveAddContributor(contributor);
        // Only two signers!
        vm.expectRevert(DonationMultiSig.NotEnoughApprovals.selector);
        multisig.addContributor(contributor);
        assertEq(multisig.isContributor(contributor), false);
    }

    function test_addContributorApprovalMinimumShouldBeTotal() public {
        address fourthSigner = address(4);
        address fifthSigner = address(5);
        testFuzz_addContributor(fourthSigner, 10);
        // Should require 4/4 signatures
        vm.startPrank(firstSigner);
        multisig.proposeAddContributor(fifthSigner, 10);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveAddContributor(fifthSigner);
        vm.stopPrank();
        vm.startPrank(thirdSigner);
        multisig.approveAddContributor(fifthSigner);
        vm.expectRevert(DonationMultiSig.NotEnoughApprovals.selector);
        multisig.addContributor(fifthSigner);
    }

    function test_addContributorApprovalMinimumShouldBeLessThanTotal() public {
        address fourthSigner = address(4);
        address fifthSigner = address(5);
        address sixthSigner = address(6);
        testFuzz_addContributor(fourthSigner, 10);
        vm.startPrank(firstSigner);
        multisig.proposeAddContributor(fifthSigner, 10);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveAddContributor(fifthSigner);
        vm.stopPrank();
        vm.startPrank(thirdSigner);
        multisig.approveAddContributor(fifthSigner);
        vm.stopPrank();
        vm.startPrank(fourthSigner);
        multisig.approveAddContributor(fifthSigner);
        multisig.addContributor(fifthSigner);
        assertEq(multisig.isContributor(fifthSigner), true);
        // Should only require 3/5 signatures
        testFuzz_addContributor(sixthSigner, 10);
    }

    function test_proposeRemoveContributor() public {
        vm.startPrank(firstSigner);
        multisig.proposeRemoveContributor(thirdSigner);
        bool exists;
        uint32 propWeight;
        uint8 approvalCount;
        (exists, propWeight, approvalCount) = multisig.removeProposals(thirdSigner);
        assertEq(approvalCount, 0);
        assertEq(exists, true);
        assertEq(propWeight, 0);
    }

    function test_approveRemoveContributor() public {
        vm.startPrank(firstSigner);
        // Approval is implied by proposer
        multisig.proposeRemoveContributor(thirdSigner);
        uint8 approvalCount;
        (,,approvalCount) = multisig.removeProposals(thirdSigner);
        assertEq(approvalCount, 0);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveRemoveContributor(thirdSigner);
        uint8 approvalCount2;
        (,,approvalCount2) = multisig.removeProposals(thirdSigner);
        assertEq(approvalCount2, 1);
        vm.stopPrank();
        vm.startPrank(thirdSigner);
        multisig.approveRemoveContributor(thirdSigner);
        uint8 approvalCount3;
        (,,approvalCount3) = multisig.removeProposals(thirdSigner);
        assertEq(approvalCount3, 2);
        assertEq(multisig.isContributor(thirdSigner), true);
        multisig.removeContributor(2);
        assertEq(multisig.isContributor(thirdSigner), false);
    }

    function test_approveRemoveContributorNotEnoughApprovals() public {
        vm.startPrank(firstSigner);
        // Approval is implied by proposer
        multisig.proposeRemoveContributor(thirdSigner);
        uint8 approvalCount;
        (,,approvalCount) = multisig.removeProposals(thirdSigner);
        assertEq(approvalCount, 0);
        vm.stopPrank();
        vm.startPrank(secondSigner);
        multisig.approveRemoveContributor(thirdSigner);
        uint8 approvalCount2;
        (,,approvalCount2) = multisig.removeProposals(thirdSigner);
        assertEq(approvalCount2, 1);
        vm.stopPrank();
        vm.startPrank(firstSigner);
        // Only two proposals!
        vm.expectRevert(DonationMultiSig.NotEnoughApprovals.selector);
        multisig.removeContributor(2);
        assertEq(multisig.isContributor(thirdSigner), true);
    }

    function _donate(
        uint256 amount,
        bool token
    ) public {
        if (!token) {
            deal(address(this), amount);
            (bool success,) = address(multisig).call{value: amount}("");
            assertEq(success, true);
            assertEq(address(multisig).balance, amount);
        } else {
            deal(address(mockToken), address(this), amount);
            bool success = mockToken.transfer(address(multisig), amount);
            assertEq(success, true);
            assertEq(mockToken.balanceOf(address(multisig)), amount);
        }
    }

    function testFuzz_donateETH(uint amount) public {
        _donate(amount, false);
    }

    function testFuzz_donateToken(uint amount) public {
        _donate(amount, true);
    }

    function test_distributeETHNotWorthSplitting() public {
        _donate(29, false);
        vm.startPrank(firstSigner);
        vm.expectRevert(abi.encodeWithSelector(DonationMultiSig.NotWorthSplitting.selector, address(0), 29));
        multisig.distribute(address(0));
        vm.stopPrank();
    }

    function test_distributeETH() public {
        _donate(1000, false);
        vm.startPrank(firstSigner);
        multisig.distribute(address(0));
        vm.stopPrank();
        assertEq(address(firstSigner).balance, 330);
        assertEq(address(secondSigner).balance, 330);
        assertEq(address(thirdSigner).balance, 330);
        assertEq(address(multisig).balance, 10);
    }

    function testFuzz_distributeETH(uint amount) public {
        vm.assume(amount >= 30);
        _donate(amount, false);
        uint total = address(multisig).balance;
        uint signerQuantity = (total / multisig.totalWeight()) * 10;
        uint leftInContract = total - (signerQuantity * 3);
        vm.startPrank(firstSigner);
        multisig.distribute(address(0));
        vm.stopPrank();
        
        assertEq(address(firstSigner).balance, signerQuantity);
        assertEq(address(secondSigner).balance, signerQuantity);
        assertEq(address(thirdSigner).balance, signerQuantity);
        assertEq(address(multisig).balance, leftInContract);
    }
    
    function test_distributeToken() public {
        _donate(1000, true);
        vm.startPrank(firstSigner);
        multisig.distribute(address(mockToken));
        vm.stopPrank();
        assertEq(mockToken.balanceOf(firstSigner), 330);
        assertEq(mockToken.balanceOf(secondSigner), 330);
        assertEq(mockToken.balanceOf(thirdSigner), 330);
        assertEq(mockToken.balanceOf(address(multisig)), 10);
    }

    function testFuzz_distributeToken(uint amount) public {
        vm.assume(amount >= 30);
        _donate(amount, true);
        uint total = mockToken.balanceOf(address(multisig));
        uint signerQuantity = (total / multisig.totalWeight()) * 10;
        uint leftInContract = total - (signerQuantity * 3);
        vm.startPrank(firstSigner);
        multisig.distribute(address(mockToken));
        vm.stopPrank();
        
        assertEq(mockToken.balanceOf(firstSigner), signerQuantity);
        assertEq(mockToken.balanceOf(secondSigner), signerQuantity);
        assertEq(mockToken.balanceOf(thirdSigner), signerQuantity);
        assertEq(mockToken.balanceOf(address(multisig)), leftInContract);
    }

    function test_distributeTokenNotWorthSplitting() public {
        _donate(29, true);
        vm.startPrank(firstSigner);
        vm.expectRevert(abi.encodeWithSelector(DonationMultiSig.NotWorthSplitting.selector, address(mockToken), 29));
        multisig.distribute(address(mockToken));
        vm.stopPrank();
    }
}