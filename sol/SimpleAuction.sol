pragma solidity ^0.4.11;

contract SimpleAuction {
    // オークションのパラメータ
    // 時間の変数に関してはunixタイムスタンプ、もしくは 期間の秒数を設定する
    // 出品者
    address public beneficiary;
    // オークションの開始時間（Unixタイムスタンプ？）
    uint public auctionStart;
    // オークション期間（秒数）
    uint public biddingTime;

    // オークションの現在の状態を表す変数
    // 最高額入札者
    address public highestBidder;
    // 入札額
    uint public highestBid;

    // 前の入札の払い戻しを許可するためのmap
    mapping(address => uint) pendingReturns;

    // trueの場合終了を表し、どのような変更も受け付けない
    bool ended;

    // 変更時に発行されるイベント
    // 最高入札額の更新イベント
    event HighestBidIncreased(address bidder, uint amount);
    // オークションの終了イベント
    event AuctionEnded(address winner, uint amount);


    /// simple auctionを作成
    /// `_biddingTime` 入札秒を指定
    /// `_beneficiary` 入札者アドレス
    function SimpleAuction(uint _biddingTime, address _beneficiary) {
        beneficiary = _beneficiary;
        auctionStart = now;
        biddingTime = _biddingTime;
    }

    /// トランザクションと一緒に送信された送金値でオークションに入札。
    /// オークションに勝っていない場合にのみ送金値が払い戻されます。
    function bid() payable {
        // 引数はない、すべての情報既にトランザクションに入っている。
        // Etherを受信できるようにするには payable キーワードが必要

        // 期間が終了している場合は、入札額を返す
        require(now <= (auctionStart + biddingTime));

        // 入札額が現在の最高入札額に届かかない場合返金する
        require(msg.value > highestBid);

        if (highestBidder != 0) {
            // 返金する場合にhighestBidder.send(highestBid)を単に使うとセキュリティのリスクがあります
            // なぜならcallerによって防止できから、たとえばコールスタックを1023にあげれる
            // 受取人が自分のお金を引き値出すのは簡単

            // ２回めの入札以降の処理、過去の入札額を返すためにスタックする
            pendingReturns[highestBidder] += highestBid;
        }
        highestBidder = msg.sender;
        highestBid = msg.value;
        HighestBidIncreased(msg.sender, msg.value);
    }

    /// 超過した入札を取り消す。
    function withdraw() returns (bool) {
        var amount = pendingReturns[msg.sender];
        if (amount > 0) {
            // 0をセットすることは重要です、
            // なぜならsendが完了する前に
            // 受信者が再度呼び出すことができるから
            pendingReturns[msg.sender] = 0;

            if (!msg.sender.send(amount)) {
                // 送金に失敗した場合元に戻す
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    /// オークションの終了と最高入札額を受益者に送信
    function auctionEnd() {
        // 他のコントラクトと相互作用する関数を構造化するのは良い指針です
        // (つまり、Etherを送るか、関数を呼び出すかをわけること)
        // 3つのフェーズに分ける：
        // 1. 条件のチェック
        // 2. アクションの実行 (潜在的には条件を変更する)
        // 3. 他のコントラクトとのやりとり
        // これらのフェーズが混在している場合 他のコントラクトが現在のコントラクトに戻って状態を変更したり
        // エフェクト(Etherを支払う)を複数回実行する原因になる
        // 内部で呼び出される関数が、外部のコントラクトとのやりとりが含まれている場合、
        // その考慮しなければなりません。

        // 1. Conditions
        require(now >= (auctionStart + biddingTime)); // オークションが終了してない
        require(!ended); // この関数が既に実行されてないか

        // 2. Effects
        ended = true;
        AuctionEnded(highestBidder, highestBid);

        // 3. Interaction
        beneficiary.transfer(highestBid);
    }
}
