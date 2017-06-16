pragma solidity ^0.4.11;
contract Trade {
    uint public numTrades = 0;
    mapping (uint => TradeRow) public tradeList;

    struct TradeRow {
        address from;
        address to;
        string name;
        uint32 price;
        uint16 quantity;
    }

    // イベント
    // event Send(address from);

    // function Trade() {}

    /**
     *
     * @param from 送信者
     * @param to 受信者
     * @param name カード名 （なん文字でもOK)
     * @param price 価格 0 ～ 4,294,967,295 (wei!)
     * @param quantity 数量 0～65,535
     */
    function deal(address from, address to, string name, uint32 price, uint16 quantity) {
        tradeList[numTrades] = TradeRow(from, to, name, price, quantity);
        // Send(from);
        numTrades++;
    }

    function getName(uint tradeID) constant returns (string name){
        TradeRow t = tradeList[tradeID];
        return t.name;
    }
}
