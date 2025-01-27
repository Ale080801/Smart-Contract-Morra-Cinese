// SPDX-License-Identifier: GPL 3.0
pragma solidity ^0.8.0;

import "remix_tests.sol";
import "../contracts/RockPaperScissors.sol";
import "./PlayerProxy.sol";

contract RockPaperScissorsTest3{
    RockPaperScissors game;
    address player1;
    PlayerProxy Player1;
    address player2;
    PlayerProxy Player2;
    uint256 betAmount = 1 wei;
    
    // Funzione di setup, eseguita prima di ogni test 
    ///#value: 2
    function beforeEach() public payable {
        Assert.equal(msg.value,(2*betAmount),
        "Il valore inviato non sufficiente");
        Player1= new PlayerProxy();
        player1=address (Player1);
        Player2= new PlayerProxy();
        player2=address (Player2);
        Assert.equal(player1,address(Player1),
        "Operation Failed");
        game = new RockPaperScissors(player1, 
        player2, betAmount);
    }

    //Test claim dove solo player1 rivela
    function testClaimTimeout5() public payable{
        //deposito player1
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        //deposito player2
        hashedMove= keccak256(abi.encodePacked(uint256(3),
        "mySecret2"));//3=Scissors
        Player2.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        //reveal di player1
        Player1.callRevealMove(address(game), 1, 
        "mySecret");//1=Rock
        game.setDeadline(block.timestamp-1);
        Player1.callClaimTimeout(address(game));
        Assert.equal(player1.balance, (2*betAmount),
        "Player 1 should have got the funds");
    }

    //Test per verificare il pareggio
    function testDraw() public payable{
        //deposito player1
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        //deposito player2
        hashedMove= keccak256(abi.encodePacked
        (uint256(1), "mySecret2"));
        Player2.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        //reveal di player1
        Player1.callRevealMove(address(game), 1, 
        "mySecret");//1=Rock
        Player2.callRevealMove(address(game), 1, 
        "mySecret2");//1=Rock
        Assert.equal(player1.balance,betAmount,
        "Player1 should have got the funds back");
        Assert.equal(player2.balance,betAmount,
        "Player2 should have got the funds back");
    }

    function testClaimCreationTimeout() public payable{
        //deposito player1
        bytes32 hashedMove = keccak256(abi.encodePacked
        (uint256(1), "mySecret"));
        Player1.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        );
        //simulo il passare di 1 giorno
        //senza che nessuno faccia il claim
        game.setCreationTime((block.timestamp- 1 days)-1);
        //owner chiude il contratto congelandolo
        game.claimCreationTimeout();
        //per controllare se è congelato, provo a fare
        //il submit con player2
        try Player2.callSubmitHashedMove{value: betAmount}(
            address(game),
            betAmount,
            hashedMove
        ){
            Assert.ok(false,"Contract should be frozen");
        }catch{
            Assert.ok(true,"");
        }
    }
}