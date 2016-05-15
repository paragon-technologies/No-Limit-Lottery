// No Limit Lottery Solidity Contract

contract Owned {

	address public owner;

	function owned() {
		owner = msg.sender;
	}
	
	modifier onlyOwner() {
		if (msg.sender != owner) throw;
		_
	}
	
	function transferOwnership(address newOwner) onlyOwner {
		owner = newOwner;
	}
}


contract NoLimitLottery is Owned {

	uint public phase;
	
	/* PHASES:
	0 - 'No Lottery'
	1 - 'Commit Tickets'
	2 - 'Reveal Tickets'
	3 - 'Determine Seed'
	4 - 'Commit Solutions'
	5 - 'Reveal Solutions'
	6 - 'Determine Winner'
	*/
	
	uint8 public solverFees;
	uint8 public houseFees;
	uint public difficulty; // Use 2 ** 38?
	uint64 public ticketPrice;
	uint40 public secretLength;
	bytes32 public finalSeed;
	bytes32 public correctSolution;
	uint64 private totalSolverBets;
	
	uint64 public startBlock;
	uint64 public seedBlock;
	
	// The length of time (in number of blocks) for the different phases, use uint8 and multiply by 600 (two hours worth of blocks)
	
	uint8 public commitBlocks;
	uint8 public revealBlocks;
	uint8 public solutionBlocks;
	uint8 public solutionRevealBlocks;
	
	address[] private addrPlayers;
	uint private addrPlayersCount;
	address[] private addrSolvers;
	uint private addrSolversCount;
	address[] private winners;
	uint private winnersCount;
	
	mapping(address => Ticket[]) private tickets;
	mapping(address => uint) private ticketCounts;
	mapping(address => Solution) private solutions;
	
	struct Ticket {
		bytes32 hashCommit;
		uint64 secretNumber;
	}
	
	struct Solution {
		bytes32 hashCommit;
		uint64 nonce;
		uint64 blockNumber;
		uint64 bet;
		uint64 points;
		bool exists;
		bool validSolution;
	}
	
	// CONSTRUCTOR (runs only once)
	
	function NoLimitLottery() {
		phase = 0;
	}
	
	modifier checkPhase(uint8 functionNumber) {
		setPhase();
		
		if (functionNumber == 1 && phase == 1) {
			_
		}
		else if (functionNumber == 2 && phase == 2) {
			_
		}
		else if (functionNumber == 3 && phase == 3) {
			_
		}
		else if (functionNumber == 4 && phase == 4) {
			_
		}
		else if (functionNumber == 5 && phase == 5) {
			_
		}
		else if (functionNumber == 6 && phase == 6) {
			_
		}
		else if (phase == 3) {
			determineSeed();
		}
		else if (functionNumber == 0 && phase == 0) {
			_
		}
	}
	
	function setPhase() {
		if (phase == 0) {
			// do nothing
		}
		else if (block.number - startBlock <= commitBlocks && block.number > startBlock) {
			phase = 1;
		}
		else if (block.number - startBlock <= commitBlocks + revealBlocks && block.number - startBlock > commitBlocks) {
			phase = 2;
		}
		else if (finalSeed == bytes32(0) && block.number > startBlock ) {
			phase = 3;
		}
		else if (block.number - seedBlock <= solutionBlocks && block.number > seedBlock) {
			phase = 4;
		}
		else if (block.number - seedBlock <= solutionBlocks + solutionRevealBlocks && block.number - seedBlock > solutionBlocks) {
			phase = 5;
		}
		else if (correctSolution == bytes32(0) && block.number > startBlock) {
			phase = 6;
		}
		else if (block.number > startBlock) {
			phase = 0;
		}
	}

	function createLottery(
		uint8 _solverFees, 
		uint8 _houseFees, 
		uint _difficulty, 
		uint64 _ticketPrice,
		uint8 _secretLength,
		uint8 _commitBlocks, 
		uint8 _revealBlocks, 
		uint8 _solutionBlocks, 
		uint8 _solutionRevealBlocks
	) 
		onlyOwner
		checkPhase(0)
	{
		solverFees =  _solverFees;
		houseFees = _houseFees;
		difficulty = _difficulty;
		ticketPrice = _ticketPrice * 1 ether;
		secretLength = _secretLength;
		commitBlocks = _commitBlocks;
		revealBlocks = _revealBlocks;
		solutionBlocks = _solutionBlocks;
		solutionRevealBlocks = _solutionRevealBlocks;
		
		// Reset counts so future lotteries only process tickets for that lottery
		
		for (uint i = 0; i < addrPlayersCount; i++) {
			ticketCounts[addrPlayers[i]] = 0;
		}
		
		addrPlayersCount = 0;
		addrSolversCount = 0;
		winnersCount = 0;
		
		finalSeed = bytes32(0);
		correctSolution = bytes32(0);
		totalSolverBets = 0;
		
		startBlock = uint64(block.number);
		phase = 1;
	}

	function commitTicket(bytes32 _hashCommit) checkPhase(1) {
	
		// If the ticket purchaser sends too much ETH refund them the difference, if they 
		// send too little throw an error
		
		if (msg.value > ticketPrice) {
			msg.sender.send(msg.value - ticketPrice);
		}
		else if (msg.value < ticketPrice) {
			msg.sender.send(msg.value);
			throw;
		}
		
		if (tickets[msg.sender].length == ticketCounts[msg.sender]) {
			tickets[msg.sender].length++;
		}
		tickets[msg.sender][ticketCounts[msg.sender]] = Ticket({
															hashCommit : _hashCommit, 
															secretNumber : 0
														});
		ticketCounts[msg.sender] += 1;
		
		if (addrPlayers.length == addrPlayersCount) {
			addrPlayers.length++;
		}
		addrPlayers[addrPlayersCount] = msg.sender;
		addrPlayersCount++;
	}
	
	function revealTicket(uint64 _secretNumber) checkPhase(2) {
	
		// Verify that the secret random number chosen by the player was of the specified length 
	
		if (_secretNumber < 10 ** (secretLength - 1) || _secretNumber >= 10 ** secretLength) {
			throw;
		}
		
		// Verify that a player has a ticket with the secret number 
		
		for (uint i = 0; i < ticketCounts[msg.sender]; i++) {
			if (tickets[msg.sender][i].secretNumber == 0 && sha3(msg.sender, _secretNumber) == tickets[msg.sender][i].hashCommit) {
				tickets[msg.sender][i].secretNumber = _secretNumber;
			}
		}
	}
	
	function determineSeed() checkPhase(3) {
	
		uint numberSeed = 0; 
		
		// Combine the player numbers using bitwise exclusive or
		
		for (uint i = 0; i < addrPlayersCount; i++) {
			for (uint j = 0; j < ticketCounts[addrPlayers[i]]; j++) {
				if (tickets[addrPlayers[i]][j].secretNumber != 0) {
					numberSeed ^= uint(tickets[addrPlayers[i]][j].secretNumber); 
				}
			}
		}
		
		// XOR the numberSeed with the blockhash...in cases where the 2nd to last ticket reveal might be in a previous block this ensures that a last
		// reveal attacker has no more time than a single block to try to calculate the final random number possibilities
		
		numberSeed ^= uint(block.blockhash(block.number - 1));
		
		// Perform a final hash on the seed number
		
		finalSeed = sha3(numberSeed);
		
		seedBlock = uint64(block.number);
	}
	
	function commitSolution(bytes32 _hashCommit) checkPhase(4) {
	
		// If the solver has already submitted they cannot do so again or alter their submission
		
		if (solutions[msg.sender].exists) {
			throw;
		}
		else {
			solutions[msg.sender] = Solution({
				hashCommit : _hashCommit, 
				nonce : 0, 
				blockNumber : uint64(block.number), 
				bet : uint64(msg.value), 
				points : 0,
				exists : true, 
				validSolution : false
			});
			totalSolverBets += uint64(msg.value);
			
			if (addrSolvers.length == addrSolversCount) {
				addrSolvers.length++;
			}
			addrSolvers[addrSolversCount] = msg.sender;
			addrSolversCount++;
		}
	}
	
	function revealSolution(uint64 _nonce) checkPhase(5) {
		if (solutions[msg.sender].exists) {
			
			// Verify that the reveal matches what was committed
			
			if (sha3(msg.sender, _nonce) ==  solutions[msg.sender].hashCommit) {
				
				// Verify that the solution is legitimate
				
				if (uint(sha3(finalSeed, _nonce)) <  (2 ** 256 - 1) / difficulty ) {
					solutions[msg.sender].nonce = _nonce;
					solutions[msg.sender].validSolution = true;
				}
			}
		}
	}
	
	function determineWinner() checkPhase(6) {
	
		uint lowestNonce;
		uint winningNumber;
		uint closestDistance = 10 ** secretLength;
		int distance;
		uint lotteryBalance = this.balance;
		uint winningPayout;
		uint totalPoints;
		uint losingBets;

		// Find the valid solution with the lowest nonce to determine the correct solution 
		
		for (uint i = 0; i < addrSolversCount; i++) {
			if (solutions[addrSolvers[i]].validSolution) {
				if (i == 0) {
					lowestNonce = solutions[addrSolvers[i]].nonce;
				}
				else if (solutions[addrSolvers[i]].nonce < lowestNonce) {
					lowestNonce = solutions[addrSolvers[i]].nonce;
				}
			}
		}
		
		correctSolution = sha3(finalSeed, lowestNonce);
		
		// Convert the solution hash into a uint then mod to produce a number within the possible ticket number range given the secret length
		
		winningNumber = uint(correctSolution) % (10 ** secretLength - 10 ** (secretLength - 1));
		
		for (i = 0; i < addrPlayersCount; i++) {
			for (uint j = 0; j < ticketCounts[addrPlayers[i]]; j++) {
				if (tickets[addrPlayers[i]][j].secretNumber != 0) {
					distance = int(winningNumber - tickets[addrPlayers[i]][j].secretNumber);
					
					if (distance < 0) {
						distance *= -1;
					}
					if (uint(distance) < closestDistance) {
						closestDistance = uint(distance);

						if (winners.length == 0) {
							winners.length++;
						}
						winners[0] = addrPlayers[i];
						winnersCount = 1;
					}
					else if (uint(distance) == closestDistance) {
						if (winners.length == winnersCount) {
							winners.length++;
						}
						winners[winnersCount] = addrPlayers[i];
						winnersCount++;
					}
				}
			}
		}
		
		// Calculate how much to pay out per winning ticket 
		
		winningPayout = ((100 - (solverFees + houseFees)) * (lotteryBalance - totalSolverBets)) / (100 * winnersCount);
		
		// Pay the winners
		
		for (i = 0; i < winnersCount; i++) {
			winners[i].send(winningPayout);
		}
		
		// Calculate solver rewards
		
		for (i = 0; i < addrSolversCount; i++) {
			if (solutions[addrSolvers[i]].validSolution && solutions[addrSolvers[i]].nonce == lowestNonce) {
				solutions[addrSolvers[i]].points = 10 ** 18 * solutions[addrSolvers[i]].bet / (solutions[addrSolvers[i]].blockNumber - seedBlock); // the 10 ** 18 term preserves precision
				totalPoints += solutions[addrSolvers[i]].points;
			}
			else {
				losingBets += solutions[addrSolvers[i]].bet;
			}
		}
		
		for (i = 0; i < addrSolversCount; i++) {
			if (solutions[addrSolvers[i]].validSolution && solutions[addrSolvers[i]].nonce == lowestNonce) {
				addrSolvers[i].send((solutions[addrSolvers[i]].points * (solverFees * lotteryBalance + losingBets * 100) / (totalPoints * 10 ** 18 * 100)) + solutions[addrSolvers[i]].bet);
			}
		}
		
		// Pay out house fees
		
		owner.send(this.balance);
		
		// CREATE EVENT FOR WINNING DATA AND RESET CORRECT SOLUTION 
		
		// SOMETHING FOR IF NO ONE CAN SOLVE FOR THE SOLUTION IN TIME
		
		// OPTION TO CALCULATE DIFFICULTY BASED ON PAST LOTTERY 
	}
	
	function destroy() {
		
		// If there is a bug mid game prior to players/solvers being paid out then refund everyone and destroy the contract
		
		if (correctSolution == bytes32(0))
		{
			for (uint i = 0; i < addrPlayersCount; i++) {
				for (uint j = 0; j < ticketCounts[addrPlayers[i]]; j++) {
					addrPlayers[i].send(1 ether);
				}
			}
			
			for (i = 0; i < addrSolversCount; i++) {
				addrSolvers[i].send(solutions[addrSolvers[i]].bet);
			}
		}
	}
	
	function () {
		throw;
	}
}
