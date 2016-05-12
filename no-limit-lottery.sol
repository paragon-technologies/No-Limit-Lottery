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
	uint public lowestNonce;
	uint private totalSolverBets;
	
	// The length of time (in number of blocks) for the different phases
	
	uint public startBlock;
	uint public seedBlock;
	uint public commitBlocks;
	uint public revealBlocks;
	uint public solutionBlocks;
	uint public solutionRevealBlocks;
	
	address[] private addrSubmittedValidTicket;
	address[] private addrWithValidSolutions;
	address[] private winners;
	
	mapping(address => Ticket[]) private tickets;
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
		else if (functionName == bytes32('clearData') && phaseBytes32 == bytes32('Clear Data')) {
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
		else if (finalSeed == bytes32(0)) {
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
		else if (correctSolution == bytes32(0)) {
			phase = 'Determine Winner';
			return bytes32('Determine Winner');
		}
		else {
			phase = 'Clear Data';
			return bytes32('Clear Data');
		}
	}

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
		ticketPrice = _ticketPrice;
		commitBlocks = _commitBlocks;
		revealBlocks = _revealBlocks;
		solutionBlocks = _solutionBlocks;
		solutionRevealBlocks = _solutionRevealBlocks;
		
		startBlock = block.number;
		
		phase = 'Commit Tickets';
		noLottery = false;
	}

	function commitTicket(bytes32 _hashCommit) checkPhase(bytes32('commitTicket')) {
	
		// If the ticket purchaser sends too much ETH refund them the difference, if they 
		// send too little throw an error
		
		if (msg.value > ticketPrice) {
			msg.sender.send(msg.value - ticketPrice * 1 ether);
		}
		if (msg.value < ticketPrice) {
			msg.sender.send(msg.value);
			throw;
		}
		
		tickets[msg.sender].push(Ticket({
			hashCommit : _hashCommit, 
			secretNumber : 0,
			validTicket : false
		}));
	}
	
	function revealTicket(uint _secretNumber) checkPhase(bytes32('revealTicket')) {
	
		bool hasValidTicket; 
	
		// Verify that the secret random number chosen by the player was of the specified length 
	
		if (_secretNumber < 10 ** (secretLength - 1) || _secretNumber >= 10 ** secretLength) {
			throw;
		}
		
		// Verify that a player has a ticket with the secret number 
		
		for (uint i = 0; i < tickets[msg.sender].length; i++) {
			if (sha3(msg.sender, _secretNumber) == tickets[msg.sender][i].hashCommit) {
				tickets[msg.sender][i].secretNumber = _secretNumber;
				tickets[msg.sender][i].validTicket = true;
				hasValidTicket = true;
			}
		}
		
		if (hasValidTicket) {
			addrSubmittedValidTicket.push(msg.sender);
		}
	}
	
	function determineSeed() checkPhase(bytes32('determineSeed')) {
	
		uint _numberSeed = 0; 
		
		// Combine the player numbers using bitwise exclusive or
		
		for (uint i = 0; i < addrSubmittedValidTicket.length; i++) {
			for (uint j = 0; j < tickets[addrSubmittedValidTicket[i]].length; j++) {
				if (tickets[addrSubmittedValidTicket[i]][j].validTicket) {
					_numberSeed ^= tickets[addrSubmittedValidTicket[i]][j].secretNumber; 
				}
			}
		}
		
		// Perform a final hash on the seed number (is this necessary?)
		
		finalSeed = sha3(_numberSeed);
		
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
					
					addrWithValidSolutions.push(msg.sender);
				}
			}
		}
	}
	
	function determineWinner() checkPhase(bytes32('determineWinner')) {
	
		uint winningNumber;
		uint closestDistance = 10 ** secretLength;
		int distance;
		uint lotteryBalance = this.balance;
		uint winningPayout;
		uint totalPoints;
		uint losingBets;

		// Find the valid solution with the lowest nonce to determine the correct solution 
		
		for (uint i = 0; i < addrWithValidSolutions.length; i++) {
			if (i == 0) {
				lowestNonce = solutions[addrWithValidSolutions[i]].nonce;
			}
			else if (solutions[addrWithValidSolutions[i]].nonce < lowestNonce) {
				lowestNonce = solutions[addrWithValidSolutions[i]].nonce;
			}
		}
		
		correctSolution = sha3(finalSeed, lowestNonce);
		
		// Convert the solution hash into a uint then mod to produce a number within the possible ticket number range given the secret length
		
		winningNumber = uint(correctSolution) % (10 ** secretLength - 10 ** (secretLength - 1));
		
		for (i = 0; i < addrSubmittedValidTicket.length; i++) {
			for (uint j = 0; j < tickets[addrSubmittedValidTicket[i]].length; j++) {
				if (tickets[addrSubmittedValidTicket[i]][j].validTicket) {
					distance = int(winningNumber - tickets[addrSubmittedValidTicket[i]][j].secretNumber);
					
					if (distance < 0) {
						distance *= -1;
					}
					if (uint(distance) < closestDistance) {
						closestDistance = uint(distance);

						delete winners;
						
						winners[0] = addrSubmittedValidTicket[i];
					}
					else if (uint(distance) == closestDistance) {
						winners[winners.length] = addrSubmittedValidTicket[i];
					}
				}
			}
		}
		
		// Calculate how much to pay out per winning ticket 
		
		winningPayout = ((100 - (solverFees + houseFees)) * (lotteryBalance - totalSolverBets)) / (100 * winners.length);
		
		// Pay the winners
		
		for (i = 0; i < winners.length; i++) {
			winners[i].send(winningPayout);
		}
		
		// Calculate solver rewards
		
		for (i = 0; i < addrWithValidSolutions.length; i++) {
			if (solutions[addrWithValidSolutions[i]].validSolution && solutions[addrWithValidSolutions[i]].nonce == lowestNonce) {
				solutions[addrWithValidSolutions[i]].points = 10 ** 18 * solutions[addrWithValidSolutions[i]].bet / (solutions[addrWithValidSolutions[i]].blockNumber - seedBlock); // the 10 ** 18 term preserves precision
				totalPoints += solutions[addrWithValidSolutions[i]].points;
			}
			else {
				losingBets += solutions[addrWithValidSolutions[i]].bet;
			}
		}
		
		for (i = 0; i < addrWithValidSolutions.length; i++) {
			if (solutions[addrWithValidSolutions[i]].validSolution && solutions[addrWithValidSolutions[i]].nonce == lowestNonce) {
				addrWithValidSolutions[i].send((solutions[addrWithValidSolutions[i]].points * (solverFees * lotteryBalance + losingBets * 100) / (totalPoints * 10 ** 18 * 100)) + solutions[addrWithValidSolutions[i]].bet);
			}
		}
		
		// Pay out house fees
		
		owner.send(this.balance);
		
		// CREATE EVENT FOR WINNING DATA AND RESET CORRECT SOLUTION 
		
		// SOMETHING FOR IF NO ONE CAN SOLVE FOR THE SOLUTION IN TIME
		
		// OPTION TO CALCULATE DIFFICULTY BASED ON PAST LOTTERY 
	}
	
	function clearData() onlyOwner checkPhase(bytes32('clearData')) {
		difficulty = 0;
		solverFees = 0;
		houseFees = 0;
		ticketPrice = 0;
		secretLength = 0;
		finalSeed = bytes32(0);
		correctSolution = bytes32(0);
		lowestNonce = 0;
		totalSolverBets = 0;
		startBlock = 0;
		seedBlock = 0;
		commitBlocks = 0;
		revealBlocks = 0;
		solutionBlocks = 0;
		solutionRevealBlocks = 0;
	
		delete addrSubmittedValidTicket;
		delete addrWithValidSolutions;
		delete tickets;
		delete solutions;
		
		phase = 'No Lottery';
	}
	
	function () {
		throw;
	}
}
