pragma solidity ^0.4.11;

contract Ballot {
    // 一つの「投票者(voter)」を表す型
    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // trueの場合、その人は既にvoteしたことになる
        address delegate; // その人がdelegatedしている ??
        uint vote;   // 投票された提案のインデックス
    }

    // 一つの「提案」を表す型
    struct Proposal {
        bytes32 name;   // 短い名前 (最大32bytes)
        uint voteCount; // 累積投票数
    }

    // 「議長」を表すアドレス
    address public chairperson;

    // アドレスごとに`Voter`を格納
    mapping(address => Voter) public voters;

    // `Proposal`の動的配列
    Proposal[] public proposals;

    /// `proposalNames`を指定してballotを作成
    function Ballot(bytes32[] proposalNames) {
        // 送信者を「chairperson(議長)」とする
        chairperson = msg.sender;
        // デフォルトweigthは1
        voters[chairperson].weight = 1;

        // （引数で）指定されたproposalNamesのを順に
        // 新しいproposalオブジェクトを作成し、配列の末尾に追加します。
        for (uint i = 0; i < proposalNames.length; i++) {
            // `Proposal({...})` で一時的なProposalオブジェクトを作成し、
            // `proposals.push(...)` で`proposals`の最後に追加する
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    // `voter`にこのballotの投票権を付与する
    // `chairperson`に呼び出されることがある
    function giveRightToVote(address voter) {
        // `require`の引数が`false`と評価された場合、
        // （議長かつ指定したvoterがvoteしてない場合)
        // 終了し、すべての変化を状態とEther残金を戻します。
        // 間違って関数が呼び出されないようにする場合はこれを使用する。
        // が、gasがかかるので注意（将来的には変更される予定）
        require((msg.sender == chairperson) && !voters[voter].voted);
        voters[voter].weight = 1;
    }

    /// あなたの投票を投票先の「to」に委任します。
    function delegate(address to) {
        // 送信者がすでにvoteしていない場合
        Voter sender = voters[msg.sender];
        require(!sender.voted);

        // 自身に委任することはできない
        require(to != msg.sender);

        // Forward the delegation as long as `to` also delegated.
        // 「委任」を転送するのあれば、`to`も委任する？
        // 一般的に、このようなループは非常に危険です。
        // なぜなら、もし長い実行の場合、ブロックで利用できる以上のgasが必要になるからです。
        // この場合, delegationは実行されませんが、他の状況ではこのようなルーブは
        // contractが動かない(スタックした）状態になる
        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;

            // delegation内のループで見つかりましたが、許可されていない
            // （つまり、自身は含まない）
            require(to != msg.sender);
        }
        
        // `sender`の`voters[msg.sender].voted`を更新する
        sender.voted = true;
        sender.delegate = to;
        Voter delegate = voters[to];
        if (delegate.voted) {
            // もしdelegateが既にvoteしている場合、直接vote数を追加
            proposals[delegate.vote].voteCount += sender.weight;
        } else {
            // もしdelegateがvoteしてない場合はその人のweightを追加
            delegate.weight += sender.weight;
        }
    }

    /// `proposals[proposal].name`の提案に投票する
    /// （あなたに委任された投票権を含む）
    function vote(uint proposal) {
        Voter sender = voters[msg.sender];
        require(!sender.voted);
        sender.voted = true;
        sender.vote = proposal;

        // `proposal`が配列の範囲外である場合、
        // 例外になり、すべての変更を元に戻します。
        proposals[proposal].voteCount += sender.weight;
    }

    /// @dev すべての投票を考慮して勝利した「提案」を算出します。
    function winningProposal() constant returns (uint winningProposal) {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal = p;
            }
        }
    }

    // `proposal`配列に含まれる可決した提案の名前を取得
    // （`winningProposal()`関数を呼び出し、可決した「提案」のインデックスを取得）
    function winnerName() constant returns (bytes32 winnerName) {
        winnerName = proposals[winningProposal()].name;
    }
}
