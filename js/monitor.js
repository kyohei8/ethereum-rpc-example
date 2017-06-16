document.addEventListener("DOMContentLoaded", (event) => {
  document.body.style.fontFamily = 'sans-serif';
});


const url = 'http://localhost:8545';
let userName;
let web3;

if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider(url));
}

let stop = false;

const startMonitor = () => {
  stop = false;
  const table = document.getElementById('list');

  const BlockNo = web3.eth.blockNumber;
  for (var i = BlockNo; i >= BlockNo - 20; i--) {
    const block = web3.eth.getBlock(i);
    insertBlockRow(block, table, i);
  }
  // ブロックを確認
  console.log(web3.eth.getBlock(BlockNo));

  // setTimeout(() => { watchBlock(table, i); }, 10000);
};

const watchBlock = (table, blockNumber) => {
  if(stop){
    return;
  }

  if(blockNumber == web3.eth.blockNumber){
    setTimeout(() => {
      watchBlock(table, blockNumber);
    }, 10000);
    return;
  }

  let block = web3.eth.getBlock(blockNumber);
  insertBlockRow(block, table, blockNumber);
  setTimeout(() => {
    watchBlock(table, ++blockNumber);
  }, 10000);
};


const insertBlockRow = (result, table) => {
  let row = table.insertRow();
  const td0 = row.insertCell(0);
  td0.innerHTML = result.number;

  const td1 = row.insertCell(1);
  td1.innerHTML = new Date(parseInt(result.timestamp, 10) * 1000).toLocaleString('ja-JP-u-ca');

  const td2 = row.insertCell(2);
  td2.innerHTML = result.hash

  const td3 = row.insertCell(3);
  td3.innerHTML = result.nonce;
  const td4 = row.insertCell(4);
  if(result.transactions.length > 0){
    insertTranRow(result.transactions, td4);
  }
}

const insertTranRow = (transactions, td) => {
  let allData = '';
  for (var i = 0, len = transactions.length; i < len; i++) {
    let data = web3.eth.getTransaction(transactions[i]);
    console.table(data);
    allData += JSON.stringify(data);
  }

  // td.innerHTML = `<input type='text' value='${allData}' /></td>`
  td.innerHTML = allData;
};

const stopWatch = () => {
  stop = true;
};
