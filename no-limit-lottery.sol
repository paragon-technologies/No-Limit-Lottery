// No Limit Lottery Solidity Contract

contract owned {

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


contract NoLimitLottery is owned {

	string public phase;
	bool private noLottery;
	uint public difficulty; // Use 2 ** 38?
	uint public solverFees;
	uint public houseFees;
	uint public ticketPrice;
	uint public secretLength;
	bytes32 public finalSeed;
	bytes32 public correctSolution;
	uint private totalSolverBets;
	
	// The length of time (in number of blocks) for the different phases
	
	uint public startBlock;
	uint public seedBlock;
	uint public commitBlocks;
	uint public revealBlocks;
	uint public solutionBlocks;
	uint public solutionRevealBlocks;
	
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
		uint secretNumber;
		bool validTicket;
	}
	
	struct Solution {
		bytes32 hashCommit;
		uint nonce;
		uint blockNumber;
		uint bet;
		bool exists;
		bool validSolution;
		uint points;
	}
	
	function NoLimitLottery() {
		phase = 'No Lottery';
		noLottery = true;
	}
	
	modifier checkPhase(bytes32 functionName) {
		bytes32 phaseBytes32 = setPhase();
		
		if (functionName == bytes32('commitTicket') && phaseBytes32 == bytes32('Commit Tickets')) {
			_
		}
		else if (functionName == bytes32('revealTicket') && phaseBytes32 == bytes32('Reveal Tickets')) {
			_
		}
		else if (functionName == bytes32('determineSeed') && phaseBytes32 == bytes32('Determine Seed')) {
			_
		}
		else if (functionName == bytes32('commitSolution') && phaseBytes32 == bytes32('Commit Solutions')) {
			_
		}
		else if (functionName == bytes32('revealSolution') && phaseBytes32 == bytes32('Reveal Solutions')) {
			_
		}
		else if (functionName == bytes32('determineWinner') && phaseBytes32 == bytes32('Determine Winner')) {
			_
		}
		else if (phaseBytes32 == bytes32('Determine Seed')) {
			determineSeed();
		}
		else if (functionName == bytes32('createLottery') && phaseBytes32 == bytes32('No Lottery')) {
			_
		}
	}
	
	function setPhase() returns (bytes32) {
		if (noLottery) {
			return bytes32('No Lottery');
		}
		else if (block.number - startBlock <= commitBlocks && block.number > startBlock) {
			phase = 'Commit Tickets';
			return bytes32('Commit Tickets');
		}
		else if (block.number - startBlock <= commitBlocks + revealBlocks && block.number - startBlock > commitBlocks) {
			phase = 'Reveal Tickets';
			return bytes32('Reveal Tickets');
		}
		else if (finalSeed == bytes32(0) && block.number > startBlock ) {
			phase = 'Determine Seed';
			return bytes32('Determine Seed');
		}
		else if (block.number - seedBlock <= solutionBlocks && block.number > seedBlock) {
			phase = 'Commit Solutions';
			return bytes32('Commit Solutions');
		}
		else if (block.number - seedBlock <= solutionBlocks + solutionRevealBlocks && block.number - seedBlock > solutionBlocks) {
			phase = 'Reveal Solutions';
			return bytes32('Reveal Solutions');
		}
		else if (correctSolution == bytes32(0) && block.number > startBlock) {
			phase = 'Determine Winner';
			return bytes32('Determine Winner');
		}
		else if (block.number > startBlock) {
			phase = 'No Lottery';
			noLottery = true;
			return bytes32('No Lottery');
		}
	}
	
	//"0x616e3a2bd2a207d032423bcf0582d827206ba4ac154da2cf8dd19019b60733cd"   1069487650
	//4,1,16,1,10,5,5,5,5
	
	//0xca35b7d915458ef540ade6068dfe2f44e8fa733c
	
	tempBlock - startBlock <= commitBlocks && tempBlock > startBlock) {
			phase = 'Commit Tickets';
			return bytes32('Commit Tickets');
		}
		else if (tempBlock - startBlock <= commitBlocks + revealBlocks && tempBlock - startBlock > commitBlocks) {
	

	function createLottery(
		uint _solverFees, 
		uint _houseFees, 
		uint _difficulty, 
		uint _ticketPrice,
		uint _secretLength,
		uint _commitBlocks, 
		uint _revealBlocks, 
		uint _solutionBlocks, 
		uint _solutionRevealBlocks
	) 
		onlyOwner
		checkPhase('createLottery')
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
		
		startBlock = block.number;
		noLottery = false;
		phase = 'Commit Tickets';
	}

	function commitTicket(bytes32 _hashCommit) checkPhase(bytes32('commitTicket')) {
	
		// If the ticket purchaser sends too much ETH refund them the difference, if they 
		// send too little throw an error
		
		if (msg.value > ticketPrice) {
			msg.sender.send(msg.value - ticketPrice);
		}
		if (msg.value < ticketPrice) {
			msg.sender.send(msg.value);
			throw;
		}
		
		if (tickets[msg.sender].length == ticketCounts[msg.sender]) {
			tickets[msg.sender].length++;
		}
		tickets[msg.sender][ticketCounts[msg.sender]] = Ticket({
															hashCommit : _hashCommit, 
															secretNumber : 0,
															validTicket : false
														});
		ticketCounts[msg.sender] += 1;
		
		if (addrPlayers.length == addrPlayersCount) {
			addrPlayers.length++;
		}
		addrPlayers[addrPlayersCount] = msg.sender;
		addrPlayersCount++;
	}
	
	function revealTicket(uint _secretNumber) checkPhase(bytes32('revealTicket')) {
	
		// Verify that the secret random number chosen by the player was of the specified length 
	
		if (_secretNumber < 10 ** (secretLength - 1) || _secretNumber >= 10 ** secretLength) {
			throw;
		}
		
		// Verify that a player has a ticket with the secret number 
		
		for (uint i = 0; i < ticketCounts[msg.sender]; i++) {
			if (sha3(msg.sender, _secretNumber) == tickets[msg.sender][i].hashCommit) {
				tickets[msg.sender][i].secretNumber = _secretNumber;
				tickets[msg.sender][i].validTicket = true;
			}
		}
	}
	
	function determineSeed() checkPhase(bytes32('determineSeed')) {
	
		uint numberSeed = 0; 
		
		// Combine the player numbers using bitwise exclusive or
		
		for (uint i = 0; i < addrPlayersCount; i++) {
			for (uint j = 0; j < ticketCounts[addrPlayers[i]]; j++) {
				if (tickets[addrPlayers[i]][j].validTicket) {
					numberSeed ^= tickets[addrPlayers[i]][j].secretNumber; 
				}
			}
		}
		
		// XOR the numberSeed with the blockhash...in cases where the 2nd to last ticket reveal might be in a previous block this ensures that a last
		// reveal attacker has no more time than a single block to try to calculate the final random number possibilities
		
		numberSeed ^= uint(block.blockhash(block.number - 1));
		
		// Perform a final hash on the seed number
		
		finalSeed = sha3(numberSeed);
		
		seedBlock = block.number;
	}
	
	function commitSolution(bytes32 _hashCommit) checkPhase(bytes32('commitSolution')) {
	
		// If the solver has already submitted they cannot do so again or alter their submission
		
		if (solutions[msg.sender].exists) {
			throw;
		}
		else {
			solutions[msg.sender] = Solution({
				hashCommit : _hashCommit, 
				nonce : 0, 
				blockNumber : block.number, 
				bet : msg.value, 
				exists : true, 
				validSolution : false, 
				points : 0
			});
			totalSolverBets += msg.value;
			
			if (addrSolvers.length == addrSolversCount) {
				addrSolvers.length++;
			}
			addrSolvers[addrSolversCount] = msg.sender;
			addrSolversCount++;
		}
	}
	
	function revealSolution(bytes32 _hashSolution, uint _nonce) checkPhase(bytes32('revealSolution')) {
		if (solutions[msg.sender].exists) {
			
			// Verify that the reveal matches what was committed
			
			if (sha3(msg.sender, _hashSolution, _nonce) ==  solutions[msg.sender].hashCommit) {
				
				// Verify that the solution is legitimate
				
				if (uint(sha3(finalSeed, _nonce)) <  (2 ** 256 - 1) / difficulty ) {
					solutions[msg.sender].nonce = _nonce;
					solutions[msg.sender].validSolution = true;
				}
			}
		}
	}
	
	function determineWinner() checkPhase(bytes32('determineWinner')) {
	
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
				if (tickets[addrPlayers[i]][j].validTicket) {
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
