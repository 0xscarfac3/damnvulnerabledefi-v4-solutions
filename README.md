# Damn Vulnerable DeFi v4 Solutions

Solutions, writeups, exploit analysis, and Foundry test implementations for Damn Vulnerable DeFi v4.

Topics covered include flash loans, oracle manipulation, governance attacks, upgradeability, ABI smuggling, access control vulnerabilities, DeFi lending exploits, and smart contract security.

## About

Damn Vulnerable DeFi is a hands-on Web3 security wargame designed to teach common vulnerabilities found in decentralized finance protocols.

Each challenge contains:

- Vulnerability analysis
- Exploit development
- Foundry test implementation
- Attack walkthrough
- Key security takeaways

## Challenges

| # | Challenge      |  Status  |
|---|----------------|----------|
| 1 | [Unstoppable](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/unstoppable/README.md)    | Solved   |
| 2 | [Naive Receiver](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/naive-receiver/README.md) | Solved   |
| 3 | [Truster](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/truster/README.md)        | Solved   |
| 4 | [Side Entrance](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/side-entrance/README.md)  | Solved   |
| 5 | [The Rewarder](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/the-rewarder/README.md)   | Solved   |
| 6 | [Selfie](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/selfie/README.md)         | Solved   |
| 7 | [Compromised](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/compromised/README.md)    | Solved   |
| 8 | [Puppet](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/puppet/README.md)      | Solved   |
| 9 | [Puppet V2](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/puppet-v2/README.md)      | Solved   |
| 10 | [Free Rider](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/free-rider/README.md)    | Solved   |
| 11 | [Backdoor](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/backdoor/README.md)      | Solved   |
| 12 | [Climber](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/climber/README.md)       | Solved   |
| 13 | [Wallet Mining](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/wallet-mining/README.md) | Solved   |
| 14 | [Puppet V3](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/puppet-v3/README.md)     | Solved   |
| 15 | [ABI Smuggling](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/abi-smuggling/README.md) | Solved   |
| 16 | [Shards](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/shards/README.md)        | Solved   |
| 17 | [Curvy Puppet](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/curvy-puppet/README.md)  | Solved   |
| 18 | [Withdrawal](https://github.com/0xscarfac3/damnvulnerabledefi-v4-solutions/blob/main/damn-vulnerable-defi/src/withdrawal/README.md)    | Solved   |

> Status will be updated as I complete each challenge.

## Repository Structure

```text
.
├── unstoppable/
├── naive-receiver/
├── truster/
├── side-entrance/
├── rewarder/
├── selfie/
├── compromised/
├── puppet/
├── ...
└── README.md
```

## Goals

- Master smart contract exploitation
- Improve DeFi security knowledge
- Develop an auditor mindset
- Practice exploit development with Foundry
- Build a public record of my security research journey

## Skills Practiced

- Flash loan attacks
- Oracle manipulation
- Reentrancy
- Governance exploits
- Upgradeable proxy vulnerabilities
- Signature verification
- Merkle proof validation
- ABI smuggling
- DeFi lending attacks
- Access control failures

## Tools

- Solidity
- Foundry
- OpenZeppelin
- EVM
- DeFi Protocols

## Disclaimer

This repository is intended strictly for educational and security research purposes. All exploits are performed in intentionally vulnerable environments provided by the Damn Vulnerable DeFi challenges.

---

**Author:** [0xscarfac3](https://github.com/0xscarfac3)

*"Learn. Break. Understand. Secure."*
