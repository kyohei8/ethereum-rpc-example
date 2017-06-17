pragma solidity ^0.4.11;

contract BlindAuction {
    // 入札額
    struct Bid {
        bytes32 blindedBid; // ？
        uint deposit; // 預入金額
    }

    address public beneficiary;
    uint public auctionStart;

    uint public biddingEnd; // 入札終了時間
    uint public revealEnd;  // 開示時間
    bool public ended;    // オークションの終了フラグ

    // マップｄ配列を持つ
    mapping(address => Bid[]) public bids;

    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) public pendingReturns; // 以前の入札の払い戻しを許可するためのmap

    event AuctionEnded(address winner, uint highestBid);

    // `Modifiers` は、関数への入力を検証する便利な方法
    // 以下のコードは ` onlyBefore`が`bid`に適用されます：
    // `_`はメソッド本体に置き換えられる
    modifier onlyBefore(uint _time) {
      require(now < _time);
      _;
    }
    modifier onlyAfter(uint _time) {
      require(now > _time);
      _;
    }

    // BlindAuctionを作成
    function BlindAuction( uint _biddingTime, uint _revealTime, address _beneficiary) {
        beneficiary = _beneficiary;
        auctionStart = now;
        biddingEnd = now + _biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }

    /// `_blindedBid`は keccak256(value, fake, secret). でブラインド化する
    /// (keccak256とは暗号化ハッシュ関数でSHA-3のこと)
    /// 送信された ether は revealing phase で開示される
    /// 入札とともに送信されたetherが正しい"value"、かつ"fake"がtrue出ない場合、正しい入札とする
    /// "fake"をtrueに設定し、正確な金額は実際の入札を隠す方法ではありません、
    /// しかし 依然として必要なデポジットを作ります。
    /// 同じアドレスに複数の入札を設定できます。
    function bid(bytes32 _blindedBid) payable onlyBefore(biddingEnd) {
        bids[msg.sender].push(Bid({
            blindedBid: _blindedBid,
            deposit: msg.value
        }));
    }

    /// 入札を開示。
    /// 無効なすべての入札単価、最高入札額以外の入札額をを払い戻す
    function reveal( uint[] _values, bool[] _fake, bytes32[] _secret)
        onlyAfter(biddingEnd)
        onlyBefore(revealEnd)
    {
        uint length = bids[msg.sender].length;
        require(_values.length == length);
        require(_fake.length == length);
        require(_secret.length == length);

        uint refund;
        for (uint i = 0; i < length; i++) {
            var bid = bids[msg.sender][i];
            var (value, fake, secret) = (_values[i], _fake[i], _secret[i]);
            if (bid.blindedBid != keccak256(value, fake, secret)) {
                // 入札が実際には明らかにされてない
                // 預入金額を払い戻さない
                continue;
            }
            refund += bid.deposit;
            if (!fake && bid.deposit >= value) {
                if (placeBid(msg.sender, value))
                    refund -= value;
            }
            // 送信者が同じ預金を再請求することを不可能にします。
            bid.blindedBid = 0;
        }
        // 払い戻す
        msg.sender.transfer(refund);
    }

    // 入札を配置する（？)
    // "internal"関数
    // コントラクト自体（または派生）からのみ呼び出すことのできる関数(privateのようなも)
    function placeBid(address bidder, uint value) internal returns (bool success) {
        if (value <= highestBid) {
            return false;
        }
        if (highestBidder != 0) {
            // Refund the previously highest bidder.
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }

    /// 超過した入札を払い戻す
    function withdraw() returns (bool) {
        var amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // SimpleAuctionと同じで事前に0にする
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)){
                // No need to call throw here, just reset the amount owing
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// オークションの終了。最高入札額を受益者に送信する。
    function auctionEnd() onlyAfter(revealEnd) {
        require(!ended);
        AuctionEnded(highestBidder, highestBid);
        ended = true;
        // We send all the money we have, because some
        // of the refunds might have failed.
        beneficiary.transfer(this.balance);
    }
}
