pragma solidity ^0.4.11;

contract Purchase {
    uint public value; // 金額？
    address public seller; // 売る人
    address public buyer; // 買う人

    enum State { Created, Locked, Inactive }
    State public state;

    function Purchase() payable {
        seller = msg.sender;
        // 半分の金額
        // ２で割り切れる額を設定
        value = msg.value / 2;
        Debug(this.balance);
        require((2 * value) == msg.value);
    }

    // _conditionをチェック
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    // buyerかどうか
    modifier onlyBuyer() {
        require(msg.sender == buyer);
        _;
    }

    // sellerかどうか
    modifier onlySeller() {
        require(msg.sender == seller);
        _;
    }

    // Stateかどうか
    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived(uint value, uint balance);
    event Debug(uint balance);

    /// 購入を中止し、Etherを回収する
    /// コントラクトがロックする前にSellerによってのみ呼び出すことができる
    function abort()
        onlySeller
        inState(State.Created)
    {
        Aborted();
        state = State.Inactive;
        Debug(this.balance);
        seller.transfer(this.balance);
    }

    /// 購入者として購入を確認します。
    /// トランザクションには `2 * value` Etherが含まれていなければなりません。
    /// etherはconfirmReceivedが呼び出されるまでロックされます。
    function confirmPurchase() inState(State.Created) condition(msg.value == (2 * value)) payable {
        PurchaseConfirmed();
        buyer = msg.sender;
        state = State.Locked;
    }

    /// あなた（購入者）がアイテムを受け取ったことを確認します。
    /// これにより、ロックされたEtherが解放されます。
    function confirmReceived()
        onlyBuyer
        inState(State.Locked)
    {
        // 最初に情報を変えることが重要です
        // そうしないと、sendを使って呼び出されたコントラクトが再度ここで呼び出される
        state = State.Inactive;

        // 注：これは実際に買い手と売り手の両方が払い戻しをブロックすることを可能にします
        // withdraw パターンを使用する必要があります。
        buyer.transfer(value);
        ItemReceived(value, this.balance);
        // value分引かれたこのコントラクトが持っている金額
        // = sellerの預け額 + buyerの預け額 - (sellerの預け額 / 2(=vaule))
        seller.transfer(this.balance);
    }
}

