# Atstake - Transform your arguments into bets

Securely bet against anyone using the Ethereum blockchain.

## Blockchain betting made easy
* **Bet any amount of real money against anyone, about anything.** 
We provide an easy to use bet enforcement and tracking platform which leaves you in full control of the terms and amounts of your bets.
* **Bets are secured by an Ethereum contract.** 
All bet rules are enforced on the Ethereum blockchain with an open source contract whose code available for public review.
* **Bet against people you don't trust.** 
We use a system of incentives to ensure the outcome of your bet will be decided fairly even if you don't fully trust your opponent. You never have to worry about your opponent not paying up, because all funds are deposited prior to the start of the bet.
* **No middlemen, no extra fees.** 
Atstake never has access to your money, and you never pay us any fees. You pay only the small fee required to use the Ethereum network.

## The betting process
* **Agree to terms.** 
You create a bet proposal with all terms of the bet, and send it to your opponent and an arbiter for review. They can approve, reject, or propose edits.
* **Deposit funds to blockchain.** 
When everyone has agreed on terms, the bet is deployed to the Ethereum blockchain as a publicly verifiable contract. You and your opponent then deposit money into the contract. At this point no one can get money out of the contract unless either their opponent or the arbiter approves..
* **Report the outcome.** 
When enough time has passed for you to know the outcome of the bet, you report the outcome to the Ethereum contract.  If you and your opponent report different outcomes either of you can request that the arbiter step in and settle the disagreement. We've created incentives so that arbitration is rarely needed.
* **Winner decided.** 
The Ethereum contract uses the participants' reported outcomes to decide the winner and gives them permission to withdraw their money.

## Ensuring fair outcomes
We've created incentives so that people won't benefit from reporting false bet outcomes. There are two main components of our system: arbitration, and existing sources of reputation.
* **Arbitration.** Our bet contracts are designed with three participants: two bettors and an arbiter. When the bettors agree on the outcome the arbitor does nothing (and is not paid a fee). When the bettors disagree the arbiter decides the outcome and the arbitor's fee is paid by the bettor who disagrees with the arbiter. This system ensures that two of the three people involved would have to be dishonest to cause a bet with a clear outcome to be wrongly decided or to cause an honest person to pay an arbitration fee. Even someone who loses a bet has an incentive to report their loss accurately to avoid having to pay an arbitration fee.
* **Reputation.** If someone lies about a bet outcome, the Ethereum blockchain will contain proof that the the lie came from their Ethereum address. We make it easy to associate someone's Ethereum address with their identity by requiring anyone who uses Atstake to prove a two-way link between their Ethereum address and a Twitter username. We display these proofs on every user's public Atstake profile. The more strongly associated someone's Twitter account is with an identity that they care about, the less willing they'll be to create public proof of their dishonesty.

## Under development
Atstake has a working demo running on Rinkeby, but is still under active development with a focus on reducing gas cost, and improving the user experience.
