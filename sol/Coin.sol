pragma solidity ^0.4.11;
// 0xd826e52d711c1d1f632daa5dd8eef613f4bedf1e
contract Coin {
    // minter = 造幣者
    address minter;
    // 台帳のようなもの
    mapping (address => uint) balances;

    // イベント
    event Send(address from, address to, uint value);
    event Create(address minter, address sender);

    function Coin() {
        // 送信者を minterにする
        minter = msg.sender;
        Create(minter, msg.sender);
    }

    /**
     * 造幣する
     * minter(Coinインスタンスを発行した人）のみ発行できる
     * @param owner 通過を付与する人のアドレス
     * @param amount 造幣する金額
     */
    function mint(address owner, uint amount) {
        Create(minter, msg.sender);
        if (msg.sender != minter) return;
        balances[owner] += amount;
    }

    /**
     * 送る
     * @param receiver 受信者
     * @param amount 造幣する金額
     */
    function send(address receiver, uint amount) {
        if (balances[msg.sender] < amount) return;
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        // イベントを発行
        Send(msg.sender, receiver, amount);
    }

    /**
     * 持ち金を確認する
     * @param addr 確認したい人のアドレス
     * @return balance 金額
     */
    function queryBalance(address addr) constant returns (uint balance) {
        return balances[addr];
    }
}
