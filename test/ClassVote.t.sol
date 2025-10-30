// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/projects/ClassVote.sol";

contract ClassVoteTest is Test {
    ClassVote public classVote;
    address public admin;
    address public voter1;
    address public voter2;
    address public voter3;
    string[] public proposalNames;

    function setUp() public {
        admin = makeAddr("admin");
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");

        // Create proposal names
        proposalNames = new string[](3);
        proposalNames[0] = "Proposal A";
        proposalNames[1] = "Proposal B";
        proposalNames[2] = "Proposal C";

        vm.prank(admin);
        classVote = new ClassVote(proposalNames);

        console.log("=== ClassVote Contract Tests ===");
        console.log("Admin:", admin);
        console.log("Voter1:", voter1);
        console.log("Voter2:", voter2);
        console.log("Voter3:", voter3);
        console.log("Proposals:", proposalNames.length);
    }

    function testInitialState() public {
        console.log("Testing initial state...");

        assertEq(classVote.admin(), admin);
        assertEq(uint256(classVote.phase()), uint256(ClassVote.Phase.Setup));
        assertEq(classVote.proposalsCount(), 3);
        assertEq(classVote.voted(voter1), false);
        assertEq(classVote.voted(voter2), false);
        assertEq(classVote.voted(voter3), false);

        // Check proposal names
        (string memory name0, uint256 votes0) = classVote.proposals(0);
        (string memory name1, uint256 votes1) = classVote.proposals(1);
        (string memory name2, uint256 votes2) = classVote.proposals(2);

        assertEq(name0, "Proposal A");
        assertEq(name1, "Proposal B");
        assertEq(name2, "Proposal C");
        assertEq(votes0, 0);
        assertEq(votes1, 0);
        assertEq(votes2, 0);

        console.log("Initial state correct - Setup phase");
        console.log("Proposal A votes:", votes0);
        console.log("Proposal B votes:", votes1);
        console.log("Proposal C votes:", votes2);
    }

    function testOpenVoting() public {
        console.log("Testing open voting...");

        vm.prank(admin);
        classVote.openVoting();

        assertEq(uint256(classVote.phase()), uint256(ClassVote.Phase.Voting));
        console.log("Voting opened successfully - phase changed to Voting");
    }

    function testOpenVotingNotAdmin() public {
        console.log("Testing open voting by non-admin...");

        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("OnlyAdmin()"));
        classVote.openVoting();

        console.log("Open voting correctly rejected by non-admin");
    }

    function testOpenVotingWrongPhase() public {
        console.log("Testing open voting in wrong phase...");

        // Open voting first
        vm.prank(admin);
        classVote.openVoting();

        // Try to open again
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("PhaseError()"));
        classVote.openVoting();

        console.log("Open voting correctly rejected in wrong phase");
    }

    function testVote() public {
        console.log("Testing voting functionality...");

        // Open voting first
        vm.prank(admin);
        classVote.openVoting();

        // Voter1 votes for proposal 0
        vm.prank(voter1);
        classVote.vote(0);

        assertEq(classVote.voted(voter1), true);
        (string memory name, uint256 votes) = classVote.proposals(0);
        assertEq(votes, 1);

        console.log("Vote successful - voter1 voted for proposal 0");
        console.log("Proposal 0 votes:", votes);
        console.log("Voter1 has voted:", classVote.voted(voter1));
    }

    function testVoteAlreadyVoted() public {
        console.log("Testing vote by already voted user...");

        // Open voting first
        vm.prank(admin);
        classVote.openVoting();

        // Voter1 votes first time
        vm.prank(voter1);
        classVote.vote(0);

        // Try to vote again
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("AlreadyVoted()"));
        classVote.vote(1);

        console.log("Second vote correctly rejected - already voted");
    }

    function testVoteWrongPhase() public {
        console.log("Testing vote in wrong phase...");

        // Try to vote without opening
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("PhaseError()"));
        classVote.vote(0);

        console.log("Vote correctly rejected in Setup phase");
    }

    function testVoteInvalidIndex() public {
        console.log("Testing vote with invalid index...");

        // Open voting first
        vm.prank(admin);
        classVote.openVoting();

        // Try to vote for non-existent proposal
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("IndexOutOfBounds()"));
        classVote.vote(5);

        console.log("Vote correctly rejected with invalid index");
    }

    function testCloseVoting() public {
        console.log("Testing close voting...");

        // Open voting first
        vm.prank(admin);
        classVote.openVoting();

        // Close voting
        vm.prank(admin);
        classVote.closeVoting();

        assertEq(uint256(classVote.phase()), uint256(ClassVote.Phase.Ended));
        console.log("Voting closed successfully - phase changed to Ended");
    }

    function testCloseVotingNotAdmin() public {
        console.log("Testing close voting by non-admin...");

        // Open voting first
        vm.prank(admin);
        classVote.openVoting();

        // Try to close as non-admin
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("OnlyAdmin()"));
        classVote.closeVoting();

        console.log("Close voting correctly rejected by non-admin");
    }

    function testCloseVotingWrongPhase() public {
        console.log("Testing close voting in wrong phase...");

        // Try to close without opening
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("PhaseError()"));
        classVote.closeVoting();

        console.log("Close voting correctly rejected in Setup phase");
    }

    function testReopenVotingOnTieAllowed() public {
        // Open voting and create a tie
        vm.prank(admin);
        classVote.openVoting();

        vm.prank(voter1);
        classVote.vote(0);
        vm.prank(voter2);
        classVote.vote(1);

        // Close voting -> should mark lastRoundWasTie = true
        vm.prank(admin);
        classVote.closeVoting();
        assertEq(uint256(classVote.phase()), uint256(ClassVote.Phase.Ended));
        assertTrue(classVote.lastRoundWasTie());

        // Reopen on tie (only admin, only after Ended)
        vm.prank(admin);
        classVote.reopenVotingOnTie();
        assertEq(uint256(classVote.phase()), uint256(ClassVote.Phase.Voting));
        // Flag should reset to prevent multiple reopens without new tie
        assertFalse(classVote.lastRoundWasTie());
    }

    function testReopenVotingOnTieRejectedWithoutTie() public {
        // Open voting and produce a clear winner
        vm.prank(admin);
        classVote.openVoting();

        vm.prank(voter1);
        classVote.vote(0);
        vm.prank(voter2);
        classVote.vote(0);

        // Close voting -> no tie
        vm.prank(admin);
        classVote.closeVoting();
        assertEq(uint256(classVote.phase()), uint256(ClassVote.Phase.Ended));
        assertFalse(classVote.lastRoundWasTie());

        // Attempt reopen should revert with PhaseError (guard uses PhaseError)
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("PhaseError()"));
        classVote.reopenVotingOnTie();
    }

    function testReopenVotingOnTieOnlyAdmin() public {
        // Setup tie and close
        vm.prank(admin);
        classVote.openVoting();
        vm.prank(voter1);
        classVote.vote(0);
        vm.prank(voter2);
        classVote.vote(1);
        vm.prank(admin);
        classVote.closeVoting();
        assertTrue(classVote.lastRoundWasTie());

        // Non-admin cannot reopen
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("OnlyAdmin()"));
        classVote.reopenVotingOnTie();
    }

    function testReopenVotingOnTieWrongPhase() public {
        // In Setup phase (not Ended) -> cannot reopen
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("PhaseError()"));
        classVote.reopenVotingOnTie();

        // In Voting phase (not Ended) -> cannot reopen
        vm.prank(admin);
        classVote.openVoting();
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSignature("PhaseError()"));
        classVote.reopenVotingOnTie();
    }

    function testWinner() public {
        console.log("Testing winner function...");

        // Open voting
        vm.prank(admin);
        classVote.openVoting();

        // Vote for different proposals
        vm.prank(voter1);
        classVote.vote(0); // Proposal A gets 1 vote

        vm.prank(voter2);
        classVote.vote(1); // Proposal B gets 1 vote

        vm.prank(voter3);
        classVote.vote(0); // Proposal A gets 2 votes total

        // Close voting
        vm.prank(admin);
        classVote.closeVoting();

        // Check winner
        uint256 winnerIndex = classVote.winner();
        assertEq(winnerIndex, 0); // Proposal A should win

        console.log("Winner determined successfully - Proposal A won");
        console.log("Winner index:", winnerIndex);
    }

    function testWinnerTie() public {
        console.log("Testing winner with tie...");

        // Open voting
        vm.prank(admin);
        classVote.openVoting();

        // Create a tie
        vm.prank(voter1);
        classVote.vote(0); // Proposal A gets 1 vote

        vm.prank(voter2);
        classVote.vote(1); // Proposal B gets 1 vote

        // Close voting
        vm.prank(admin);
        classVote.closeVoting();

        // Check winner (should be first one with max votes)
        uint256 winnerIndex = classVote.winner();
        assertTrue(winnerIndex == 0 || winnerIndex == 1);

        console.log("Winner determined with tie - first max vote wins");
        console.log("Winner index:", winnerIndex);
    }

    function testWinnerWrongPhase() public {
        console.log("Testing winner in wrong phase...");

        // Try to get winner without closing
        vm.prank(admin);
        classVote.openVoting();

        vm.expectRevert(abi.encodeWithSignature("PhaseError()"));
        classVote.winner();

        console.log("Winner correctly rejected in Voting phase");
    }

    function testProposalsCount() public {
        console.log("Testing proposals count...");

        assertEq(classVote.proposalsCount(), 3);
        console.log("Proposals count:", classVote.proposalsCount());
    }

    function testCompleteVotingFlow() public {
        console.log("Testing complete voting flow...");

        // 1. Admin opens voting
        vm.prank(admin);
        classVote.openVoting();
        console.log("Step 1: Voting opened");

        // 2. Voters vote
        vm.prank(voter1);
        classVote.vote(0);
        console.log("Step 2: Voter1 voted for proposal 0");

        vm.prank(voter2);
        classVote.vote(1);
        console.log("Step 3: Voter2 voted for proposal 1");

        vm.prank(voter3);
        classVote.vote(0);
        console.log("Step 4: Voter3 voted for proposal 0");

        // 3. Admin closes voting
        vm.prank(admin);
        classVote.closeVoting();
        console.log("Step 5: Voting closed");

        // 4. Check winner
        uint256 winnerIndex = classVote.winner();
        assertEq(winnerIndex, 0); // Proposal A should win with 2 votes

        console.log("Complete voting flow successful!");
        console.log("Winner: Proposal", winnerIndex);
    }

    function testMultipleVotersSameProposal() public {
        console.log("Testing multiple voters for same proposal...");

        // Open voting
        vm.prank(admin);
        classVote.openVoting();

        // All voters vote for proposal 0
        vm.prank(voter1);
        classVote.vote(0);

        vm.prank(voter2);
        classVote.vote(0);

        vm.prank(voter3);
        classVote.vote(0);

        // Check votes
        (string memory name, uint256 votes) = classVote.proposals(0);
        assertEq(votes, 3);

        console.log("Multiple voters for same proposal successful");
        console.log("Proposal 0 total votes:", votes);
    }

    function testVoteAfterClose() public {
        console.log("Testing vote after voting is closed...");

        // Open and close voting
        vm.prank(admin);
        classVote.openVoting();

        vm.prank(admin);
        classVote.closeVoting();

        // Try to vote after closing
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("PhaseError()"));
        classVote.vote(0);

        console.log("Vote correctly rejected after voting closed");
    }

    function testProposalDetails() public {
        console.log("Testing proposal details...");

        // Check all proposals
        for (uint256 i = 0; i < classVote.proposalsCount(); i++) {
            (string memory name, uint256 votes) = classVote.proposals(i);
            console.log("Proposal %s: %s votes: %s", i, name, votes);
        }

        console.log("All proposal details retrieved successfully");
    }

    function testVoteIndexBoundary() public {
        console.log("Testing vote index boundary conditions...");

        // Open voting
        vm.prank(admin);
        classVote.openVoting();

        // Test valid indices
        vm.prank(voter1);
        classVote.vote(0); // First proposal

        vm.prank(voter2);
        classVote.vote(2); // Last proposal

        // Test invalid index
        vm.prank(voter3);
        vm.expectRevert(abi.encodeWithSignature("IndexOutOfBounds()"));
        classVote.vote(3); // Out of bounds

        console.log("Vote index boundary tests completed");
    }
}
