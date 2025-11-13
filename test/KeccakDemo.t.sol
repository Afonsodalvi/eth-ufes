import {Test} from "forge-std/Test.sol";
import {KeccakDemo} from "../src/KeccakDemo.sol";

contract KeccakDemoTest is Test {
    KeccakDemo public keccakDemo;

    function setUp() public {
        keccakDemo = new KeccakDemo();
    }

    function test_demonstrateSelectors() public {
        (bytes4 incrementSelector, bytes4 numberSelector, bytes4 setNumberSelector) = keccakDemo.demonstrateSelectors();
        assertEq(incrementSelector, bytes4(keccak256("increment()")));
        assertEq(numberSelector, bytes4(keccak256("number()")));
        assertEq(setNumberSelector, bytes4(keccak256("setNumber(uint256)")));
    }

    function test_getFullHash() public {
        bytes32 fullHash = keccakDemo.getFullHash();
        assertEq(fullHash, keccak256("increment()"));
    }
}
