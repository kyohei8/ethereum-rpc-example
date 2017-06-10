// カウンター管理用
contract CounterMaster {
    // カウンターContractのリスト
    // Contractはアドレスを指定して呼び出す必要があるため
    // アドレスとカウンターContractを対応するためのマップ情報
    mapping(address => Counter) private counters;
    // アドレスを管理する配列
    address[] private addressList;

    /**
     * カウンターContractを配列とマップに追加
     */
    function addCounter(bytes32 name) {
        // カウンターContractを作成し配列に追加
        Counter c = new Counter(name);
        addressList.push(address(c));
        counters[address(c)] = c;
    }

    /**
     * カウンターアドレスの配列をか取得
     */
    function getCounterAddressList() constant returns
      (address[] counterAddressList) {
          counterAddressList = addressList;
      }
}

contract Counter {
    // カウンター項目名
    bytes32 counterName;
    // カウント数
    uint32 numberOfCounter;

    function Counter(bytes32 name) {
        counterName = name;
    }

    /**
     * カウントアップ
     */
    function countUp() {
        numberOfCounter++;
    }

    /**
     * カウンター項目の取得
     */
    function getCounterName() constant returns (bytes32 name) {
        return counterName;
    }

    /**
     * カウント数を取得
     */
    function getNumberOfCounter() constant returns (uint32 number) {
        return numberOfCounter;
    }
}
