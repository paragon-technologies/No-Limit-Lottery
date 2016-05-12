# No Limit Lottery

In this implementation we wish to create a lottery on the Ethereum network using a provably secure decentralized random number generation scheme which allows for unlimited ticket purchases and prize winnings. 

Most Ethereum based lotteries use a blockhash in order to generate a random number so that a winner can be selected. The problem with this approach is that a miner who has also purchased tickets can potentially pass up a solution to a block in the hopes of finding another one which gives them an edge in winning the lottery. To avoid this lotteries place a 5 ETH limit on the winnings (equal to the block reward) so that miners have no incentive to risk losing a block in order to sway the outcome.

One option to avoid using a blockhash is to have participants commit random numbers hashed by their public address. Once the numbers have been committed they are revealed so that they can be combined into a final random number used to select a winner. The revealed numbers can be checked against the submitted hashes to prove that they were in fact the secret numbers which were originally committed.

The issue with this approach is that the last player to reveal has all of the information which will be used to generate the final number and as such they can choose not to reveal if it helps them (they would have likely purchased other tickets which might be helped by the decision). Whether it be a miner attack or reveal attack the last input in any decentralized "random" number generation scheme has all of the information and thus an inherent advantage over honest players.

The No Limit Lottery solves these issues by using a protocol which prevents the last input to the final number from knowing at the time whether any decision available to them will be advantageous or disadvantageous. The method begins with the committing of secret random numbers followed by a revealing phase as described above. The secret numbers are combined with a bitwise exclusive or (XOR) operation and then hashed to form a seed. Rather than using the seed to pick a winner directly however the protocol stipulates that the final random number must actually be the result of a hash of the seed along with a nonce, and that result must exist within some pre-specified subset of the 256 bit range.

The difficulty of finding a solution can be controlled by adjusting the size of the subset. Since a certain number of hashes will be statistically necessary to find a solution within any given subset a difficulty can be selected which will make it exceedingly unlikely that the last player to reveal will have the computing power necessary to calculate the alternative possible seeds and their associated solutions in order to determine whether a final number will be one which favors any of their tickets. Ideally the amount of time a reveal attacker would have between the second to last reveal and the end of the reveal phase would be no more than the Ethereum block time (aimed at 12 seconds, average ~14 seconds).

After the reveal phase anyone with hash power who wishes to collect on lottery fees can search for an answer off chain and then commit that answer (hashed with their public addresss) along with a bet. The probability P of solving for one seed is calculated as 1 - ((D - 1) / D) ^ H where D is the difficulty (the number of subsets contained in the 256 bit range) and H is the number of hashes. Thus D should be high enough that it takes someone with significant hashing power several hours to solve whereas low enough that someone with low to medium hashing power can solve in a time frame which makes it more profitable than simply hashing for Ethereum block rewards.

Once the solutions are committed they are revealed and any correct answers with the lowest nonce get rewarded by the contract. The lowest nonce requirement prevents a miner from selecting between various possible solutions in a manner which favors a certain outcome.

Any incorrect submissions result in lost bets whereas correct solutions result in lottery fee rewards paid out according to (1) submission time and (2) bet size. In particular the number of "points" awarded to a solver is inversely proportional to the number of blocks it took to commit a solution and directly proportional to the amount of the bet. Their share of the fees then is respresented by their percentage of the overall number of points earned by all solvers.

In general here are the phases of a Super Lottery:

(1) COMMIT PHASE - Players purchase tickets by sending X ETH to the contract along with a hash of their public key together with a random number of a specified length (thus keeping their choice of random number a secret).

(2) REVEAL PHASE - Players reveal their secret random numbers and the contract verifies that this is indeed what they originally submitted. Anyone who fails to reveal forfeits their ETH.

(3) SEED PHASE - The contract performs successive XOR operations on the revealed random numbers and hashes the end result to produce a seed.

(4) SOLUTION PHASE - Anyone with hash power wishing to collect lottery fees hashes the random seed with a nonce until they find a result which exists within a pre-specified range of the 256 bit space. Solutions are hashed with the public key of the submitter to keep them a secret. Earlier correct solutions and larger bets are rewarded with a greater share of the lottery fees.

(5) SOLUTION REVEAL PHASE - Solvers reveal their answers. The contract verifies each submitted solution and selects as the correct answer those with the lowest nonce.

(6) LOTTERY PICK PHASE - The contract uses the final random number to pick a winner and reward the money. It then pays out the solvers according to submission time and amount bet.
