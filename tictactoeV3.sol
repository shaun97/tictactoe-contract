// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

contract TicTacToe {
    
    enum Symbol { EMPTY, X, O }
    enum Status { WAITING_FOR_PLAYER, PLAYER_ONE_MOVE, PLAYER_TWO_MOVE, PLAYER_ONE_WON, PLAYER_TWO_WON, BOT_WON, DRAW }
    enum GameType { BOT, PLAYER }
    
    uint256 greenPot;
    
    struct Game {
        // Players
        address playerOne; // Player 1 X
        address playerTwo; // Player 2 other_player
        
        // Symbol
        Symbol playerOneSymbol;
        Symbol playerTwoSymbol;
        
        //Status
        Status gameStatus;
        GameType gameType;
        
        uint256 bet;
        
        Symbol[9] board;
    }
    
    struct Player {
        address player;
        uint256 score;
    }
    
    //constructor() public {
    //    greenPot = 0;
    //}
        
    mapping(address => uint256) public players;     // mapping to store player and the gameId
    mapping(uint256 => Game) public games;          // mapping to store the player's board with gameId
    mapping(address => uint256) public scoreboard;
    mapping (uint256 => Player) public leaderboard;
    
    address[] public playersArray;
    uint256[] public gamesArray;
    
    function createGame(uint256 _bet, bool isBot) public {
        uint256 gameId = gamesArray.length;
        gamesArray.push(gameId);
        players[msg.sender] = gameId;

        games[gameId] = Game({
            playerOne: msg.sender,
            playerTwo: address(0),
            playerOneSymbol: Symbol.X,
            playerTwoSymbol: Symbol.EMPTY,
            gameStatus: Status.WAITING_FOR_PLAYER,
            gameType: GameType.PLAYER,
            bet: _bet,
            board: [Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY, Symbol.EMPTY]
        });
        
        Game storage board = games[gameId];
        
        if (isBot) {
            board.gameType = GameType.BOT;
            board.playerOneSymbol = Symbol.X;
            board.playerTwoSymbol = Symbol.O;
            
            //TODO Randomised
            if (generateRandomStart() == 1) { //bot starts, bot is player two
                int move = botMove(board.board, board.playerTwoSymbol, board.playerOneSymbol);
                board.board[uint256(move)] = board.playerTwoSymbol;
                board.gameStatus = Status.PLAYER_TWO_MOVE;
            } else {
                board.gameStatus = Status.PLAYER_ONE_MOVE;
            }
        }        
    }
    
    //Helper functions
    function generateRandomStart() internal view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, playersArray))) % 2;
    }
    
    function botMove(Symbol[9] memory board, Symbol botSymbol, Symbol playerSymbol) pure internal returns(int) {
        
        // Put centre if possible
        if (board[4] == Symbol.EMPTY) {
            return 4;
        }
    
        for(int i = 0; i < int(board.length); i++) {
            if (board[uint256(i)] == Symbol.EMPTY) {
                board[uint256(i)] = botSymbol;
                
                // If can win, win
                int score = evaluate(board, botSymbol, playerSymbol);
                if (score == 1) {
                    return i;
                }
                
                // Remove
                board[uint256(i)] = Symbol.EMPTY;
            }
        }
        
        // If opponent is 1 away from winning
        for(int i = 0; i < int(board.length); i++) {
            if (board[uint256(i)] == Symbol.EMPTY) {
                // Opponent move
                board[uint256(i)] = playerSymbol;
                
                int oppScore = evaluate(board, playerSymbol, botSymbol);
                
                // If opponent can win with one more move, block it
                if (oppScore == 1) {
                    return i;
                }
            }
        }
        
        // Place it somewhere along the path of the opponents move
        for(int i = 0; i < int(board.length); i++) {
            if (board[uint256(i)] == playerSymbol) {
                for (int j = -4; i < 5; j++) {
                    if (j + i >= 0 && j + i < 9) {
                        return j + i;
                    }
                }
            }
        }
        
        return -1;
    } 
    
    function evaluate(Symbol[9] memory gameboard, Symbol player, Symbol opponent) internal pure returns(int) {
        uint8[3][8] memory winningStates = [
            [0, 1, 2], [3, 4, 5], [6, 7, 8],
            [0, 3, 6], [1, 4, 7], [2, 5, 8],
            [0, 4, 8], [6, 4, 2]
            ];
        
        for (uint8 i = 0; i < winningStates.length; i++) {
            uint8[3] memory winningState = winningStates[i];
            if (
                gameboard[winningState[0]] == player && 
                gameboard[winningState[1]] == player && 
                gameboard[winningState[2]] == player) {
                    return 1;
            } else if (
                gameboard[winningState[0]] == opponent && 
                gameboard[winningState[1]] == opponent && 
                gameboard[winningState[2]] == opponent) {
                    return -1;
            }
        }
        return 0;
    }
    
    function isMovesLeft(Symbol[9] memory gameboard) internal pure returns(bool) {
        for(uint8 i = 0; i < gameboard.length; i++) {
            if (gameboard[i] == Symbol.EMPTY) {
                return true;
            }
        }
        return false;
    }
    
    function makeMove(uint8 position) public returns (string memory) {
        uint256 gameID = players[msg.sender];
        Game storage _game = games[gameID];
        
        // Check that game is still in IN_PROGRESS
        require(_game.gameStatus == Status.PLAYER_ONE_MOVE || _game.gameStatus == Status.PLAYER_TWO_MOVE);
        
        // Check if it is a valid position
        require(position >= 0 && position <= 8);

        Symbol playerSymbol;
        Symbol otherPlayerSymbol;
        
        if (_game.playerOne == msg.sender) {
            playerSymbol = _game.playerOneSymbol;
            otherPlayerSymbol = _game.playerTwoSymbol;
        } else {
            playerSymbol = _game.playerTwoSymbol;
            otherPlayerSymbol = _game.playerOneSymbol;
        }
        
        // Check if a piece is already there
        Symbol boardPosition = _game.board[position];
        require(boardPosition == Symbol.EMPTY);
        
        // Make the move
        _game.board[position] = playerSymbol;
        
         if (_game.gameType == GameType.BOT) {
            //bot move
            int move = botMove(_game.board, otherPlayerSymbol, playerSymbol);
            _game.board[uint256(move)] = otherPlayerSymbol;
            
            if (evaluate(_game.board, otherPlayerSymbol, playerSymbol) == 1) {
                _game.gameStatus = Status.BOT_WON;
                //other_player.transfer(wagers_[other_player]); //Other player wins - Wager goes to other player
                return "lost";
            }
            
            if (isMovesLeft(_game.board) == false) {
                _game.gameStatus = Status.DRAW;
                return "draw";
            }
        } else if (_game.gameType == GameType.PLAYER) {
            //check win
            if (evaluate(_game.board, playerSymbol, otherPlayerSymbol) == 1) {
                
                if (playerSymbol == _game.playerOneSymbol) {
                    _game.gameStatus = Status.PLAYER_ONE_WON;
                    // playerTwo.transfer(_game.bet)
                } else {
                    _game.gameStatus = Status.PLAYER_TWO_WON;
                }
    
                update_scoreboard();
                update_leaderboard();
                
                //TODO 
                // host_player.transfer(wagers_[host_player]); //Host player wins - Wager goes to host player
                return "win";
            }
                
            if (isMovesLeft(_game.board) == false) {
                _game.gameStatus = Status.DRAW;
                
                //We take money
                return "draw";
            }
        }
        return "next move";
    }
    
    
    function joinGame(uint256 _gameId) public returns (bool success, string memory reason) {
        if (gamesArray.length == 0 || _gameId > gamesArray.length) {
            return (false, "No such game exists.");
        }
        
        address player = msg.sender;
        Game storage game = games[_gameId];
        
        if (player == game.playerOne) {
            return (false, "You can't play against yourself.");
        }
        
        // Assign the new player to slot 2 if it is empty.
        if (game.playerTwoSymbol == Symbol.EMPTY) {
            game.playerTwo = player;
            game.playerTwoSymbol = Symbol.O;
            game.gameStatus = Status.PLAYER_ONE_MOVE;
            //emit PlayerJoinedGame(_gameId, player, uint8(players.playerTwo));
            return (true, "Joined as player Two player. Player one can make the first move.");
        }
        return (false, "All seats taken.");
    }
    
    function getBoard() public view returns (Symbol[9] memory, uint256 symbol) {
        uint256 playerSymbol;
        uint256 gameId = players[msg.sender];
        Game storage game = games[gameId];
        
        if (game.playerOne == msg.sender) {
            playerSymbol = (game.playerOneSymbol == Symbol.X) ? 1: 0;
        } else {
            playerSymbol = (game.playerTwoSymbol == Symbol.X) ? 1: 0;
        }
        return (games[gameId].board, playerSymbol);
    }
    
    function getNumofGames() public view returns (uint256) {
        return gamesArray.length;
    }
    
    function gameStats() public view returns (uint256 openGame, uint256 gameInProgress, uint256 gameOver) {
        uint256 open = 0;
        uint256 inProgress = 0;
        uint256 over = 0;
        
        for (uint256 i = 0; i < gamesArray.length; i++) {
            Game storage game = games[i];
            if (game.gameStatus == Status.WAITING_FOR_PLAYER) {
                open ++;
            } else if (game.gameStatus == Status.PLAYER_ONE_MOVE || game.gameStatus == Status.PLAYER_TWO_MOVE) {
                inProgress ++;
            } else {
                over ++;
            }
        }
        return (open, inProgress, over);
    }
    
    
    //=============leaderboard=============
    function update_scoreboard() public {
        scoreboard[msg.sender] += 1;
    }

    function get_score(address player) public view returns(uint256) {
        return scoreboard[player];
    }
    
    function update_leaderboard() public {
        uint maxLen = 10;
        uint256 player_score = get_score(msg.sender);

        if (player_score > leaderboard[maxLen-1].score) {
            for (uint i = 0; i < maxLen; i ++) {
                if (player_score > leaderboard[i].score) {
                    if (msg.sender == leaderboard[i].player) {
                        leaderboard[i].score = player_score;
                    } else { //shift down
                        Player memory curr_player = leaderboard[i];
                        for (uint j = i + 1; j < maxLen + 1; j ++) {
                            Player memory next_player = leaderboard[j];
                            leaderboard[j] = curr_player;
                            curr_player = next_player;
                        }
                        
                        leaderboard[i] = Player({
                            player: msg.sender,
                            score: player_score
                        });
                    }
                }
            }
            delete leaderboard[maxLen];
        }
    }
}