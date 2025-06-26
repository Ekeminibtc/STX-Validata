
# STX-Validata - Decentralized Peer-Review Publishing System

A Clarity smart contract for a **blockchain-based academic publishing and peer-review protocol**. The system allows researchers to submit research papers, incentivizes reviewers with STX rewards, and ensures transparent and tamper-proof review records.

---

## ✨ Features

* 📝 **Submit Papers**: Authors can submit research using an IPFS hash and assign a unique paper ID.
* 👩‍⚖️ **Reviewer Registration**: Anyone can become a reviewer by staking a minimum STX amount.
* 🧪 **Submit Reviews**: Verified reviewers can review papers with scores and comments (referenced via IPFS).
* 🪙 **Earn Rewards**: Reviewers are rewarded in STX after submitting valid reviews.
* ⚠️ **Challenge Reviews**: Users can challenge unfair or malicious reviews by staking a challenge fee.
* 🔐 **Role-Based Access**: Paper owners can update statuses; contract owner can manage global settings and pause reviewers.
* 🔍 **Transparent History**: All reviews, papers, and reviewer reputations are stored immutably on-chain.

---

## 🔧 Smart Contract Architecture

### 🗃 Data Structures

* `Papers`: Maps `paper-id` to paper metadata (author, IPFS hash, status, etc.).
* `Reviews`: Stores individual reviews linked to papers and reviewers.
* `Reviewers`: Maintains reviewer status, stake, review count, and reputation.

### 📥 Public Functions

| Function                                            | Description                                         |
| --------------------------------------------------- | --------------------------------------------------- |
| `submit-paper(ipfs-hash, paper-id)`                 | Submits a new paper.                                |
| `register-reviewer()`                               | Registers as a reviewer by staking STX.             |
| `submit-review(paper-id, score, comment-hash)`      | Submits a review and earns rewards.                 |
| `withdraw-stake()`                                  | Withdraws stake if the reviewer is paused/inactive. |
| `challenge-review(paper-id, reviewer, reason)`      | Challenges a submitted review.                      |
| `update-paper-status(paper-id, new-status)`         | Updates paper status (by author).                   |
| `update-settings(new-min-stake, new-review-reward)` | Admin function to adjust economic parameters.       |
| `pause-reviewer(reviewer)`                          | Admin function to pause a reviewer.                 |

### 📖 Read-Only Functions

| Function                                 | Description                                 |
| ---------------------------------------- | ------------------------------------------- |
| `get-paper-details(paper-id)`            | Retrieves paper metadata.                   |
| `get-review-details(paper-id, reviewer)` | Retrieves specific review data.             |
| `get-reviewer-details(reviewer)`         | Shows reviewer stats and status.            |
| `get-reviewer-earnings(reviewer)`        | Calculates total earnings based on reviews. |

---

## 📊 Reviewer Incentives

* **Minimum Stake**: `min-stake` (default: 100 STX)
* **Reward Per Review**: `review-reward` (default: 50 STX)
* **Reputation Tracking**: Reputation increases with each review and can be used to measure reviewer reliability.

---

## 🔐 Error Handling

Defined constants ensure consistent and descriptive error codes:

| Code   | Description          |
| ------ | -------------------- |
| `u100` | Not authorized       |
| `u101` | Paper not found      |
| `u102` | Already reviewed     |
| `u103` | Invalid score        |
| `u104` | Insufficient balance |
| `u105` | Not a reviewer       |
| `u106` | Paper already exists |
| `u107` | Empty hash           |
| `u108` | Invalid ID           |
| `u109` | Empty reason         |
| `u110` | Self-challenge       |
| `u111` | Empty status         |
| `u112` | Invalid status       |
| `u113` | Already registered   |

---

## 🧪 Example Usage

```lisp
;; Author submits a paper
(submit-paper "Qm123..." u1)

;; User registers as a reviewer
(register-reviewer)

;; Reviewer submits a review
(submit-review u1 u85 "QmCommentHash...")

;; Author updates paper status
(update-paper-status u1 "accepted")
```

---

## 🚨 Security and Design Considerations

* **Staking ensures reviewer accountability**.
* **Review challenges prevent bias or manipulation**.
* **Rewards are locked until reviews are submitted correctly**.
* **Reputation and review count track contribution levels**.
* **Papers and reviews are IPFS-referenced, reducing on-chain storage costs**.

---

## 🧾 License

This smart contract is provided under the MIT License. See `LICENSE` for details.

---
