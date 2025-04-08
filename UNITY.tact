import "@stdlib/deps/stdlib"
import { JettonWallet } from "@stdlib/jetton/JettonWallet"
import { JettonMinter } from "@stdlib/jetton/JettonMinter"
import { Builder } from "@stdlib/Builder"
import { Dictionary } from "@stdlib/Dictionary"

contract UNITY {
    owner: Address
    treasury: Dictionary<Address, Coins>
    totalSupply: Int
    balances: Dictionary<Address, Int>
    jettonMinter: JettonMinter

    init(owner: Address) {
        self.owner = owner
        self.treasury = Dictionary.empty()
        self.totalSupply = 0
        self.balances = Dictionary.empty()
        self.jettonMinter = JettonMinter.init(owner)
    }

    receive("mint", queryId: Int, amount: Int, for: Address) {
        require(ctx.sender == self.owner)
        self.totalSupply += amount
        let current = self.balances.get(for).unwrap_or(0)
        self.balances.set(for, current + amount)
        self.jettonMinter.mint(for, amount, queryId)
    }

    receive("transfer", amount: Int, to: Address) {
        let sender = ctx.sender
        let balance = self.balances.get(sender).unwrap_or(0)
        require(balance >= amount)
        self.balances.set(sender, balance - amount)
        let recipientBalance = self.balances.get(to).unwrap_or(0)
        self.balances.set(to, recipientBalance + amount)
    }

    receive("depositToken", token: Address, amount: Coins) {
        require(ctx.sender == self.owner)
        let current = self.treasury.get(token).unwrap_or(0)
        self.treasury.set(token, current + amount)
    }

    receive("redeem", amount: Int) {
        let sender = ctx.sender
        let balance = self.balances.get(sender).unwrap_or(0)
        require(balance >= amount)
        self.balances.set(sender, balance - amount)
        self.totalSupply -= amount

        for (token, totalAmount) in self.treasury {
            let share = (totalAmount * amount) / self.totalSupply
            JettonWallet(token).transfer(sender, share, 0)
            let newTotal = totalAmount - share
            self.treasury.set(token, newTotal)
        }
    }

    receive("vote", action: Slice) {
        require(ctx.sender == self.owner)
    }

    get fun getBalance(addr: Address): Int {
        return self.balances.get(addr).unwrap_or(0)
    }

    get fun getTreasury(): Dictionary<Address, Coins> {
        return self.treasury
    }

    get fun getTotalSupply(): Int {
        return self.totalSupply
    }
}
