const url = 'http://localhost:8545';
let userName;
let web3;

if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider(url));
}

/*
web3.eth.defaultAccount = web3.eth.accounts[0];
for (var i = 0, len = 99; i < len; i++) {
  web3.personal.newAccount();
}
console.log('done!');
*/

const tradeABI = [{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"tradeList","outputs":[{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"name","type":"string"},{"name":"price","type":"uint32"},{"name":"quantity","type":"uint16"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"from","type":"address"},{"name":"to","type":"address"},{"name":"name","type":"string"},{"name":"price","type":"uint32"},{"name":"quantity","type":"uint16"}],"name":"deal","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"tradeID","type":"uint256"}],"name":"getName","outputs":[{"name":"name","type":"string"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"numTrades","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"name":"from","type":"address"}],"name":"Send","type":"event"}];
const contractAddress = "0xf2dccceda6f8b48f6ab04be989ada0bf308b4c03";

const master = web3.eth.contract(tradeABI).at(contractAddress);
// TODO getterを書く
// const numTrade = master.numTrades().c[0];
// console.log(numTrade);
// for (var i = 0, len = numTrade - 1; i < len; i++) {
  // console.log(master.tradeList(i));
// }
// console.log(master.tradeList(2));
// web3.eth.defaultAccount = "0xf5290627291e0dd723741ead15ca20242aeccdd2";
// console.log(master.deal(
// "0xf5290627291e0dd723741ead15ca20242aeccdd2",
// "0xf5290627291e0dd723741ead15ca20242aeccdd2",
// "a", 1, 1, {gas: 150000}));


/**
 * ログイン
 */
const login = () => {
  userName = $('#user-name').val();
  const password = $('#password').val();
  const jsonData = createJSONdata("personal_unlockAccount", [
    userName, password, 30
  ]);

  executeJsonRpc(url, jsonData, (data) => {
    // Success
    if(data.error == null){
      console.log(data.error);
      console.log('login sucess');
    } else {
      console.log('login error');
    }
  }, (data) => {
    // fail
    console.log('login error');
  });
};

const sampleAccount = (dep) => {
  web3.eth.getAccounts((e, res) => {
    if(e) return;
    const accounts = res;
    if(dep){
      let acc = '';
      do {
        acc = sampleAccount();
      } while (acc === dep);
      return acc;
    }else{
      return accounts[Math.floor(Math.random() * accounts.length)];
    }
  });
}
const sampleCN = () => CN[Math.floor(Math.random() * CN.length)];
const samplePrice = () => +(Math.random() * 60000).toFixed(0);
const sampleAmmount = () => +(Math.random() * 1000).toFixed(0);

// console.log(sampleCN());
// console.log(samplePrice());
const from = sampleAccount();
const to = sampleAccount(from);
// console.log(from, to, sampleCN(), samplePrice(), sampleAmmount());

const addTx = () => {
  web3.eth.defaultAccount = "0xf5290627291e0dd723741ead15ca20242aeccdd2";
  const from = sampleAccount();
  const to = sampleAccount(from);
  const tx = master.deal(
    from, to, sampleCN(), samplePrice(),
    sampleAmmount(), {
      gas: 118500
    }
  );
  console.log('add', tx);
};

const reload = () => {

  console.time('elements');
  const numTrade = master.numTrades().c[0];
  $('#num').text(`${numTrade}件`);
  let list = ''
  for (var i = 0, len = numTrade - 1; i < len; i++) {
    const t = master.tradeList(i);
    list += `<li>${t[0]}, ${t[1]}, ${t[2]}, ${t[3].c[0]}, ${t[4].c[0]}</li>`
  }
  console.timeEnd('elements');
  $('#list').html(list);
  console.log('load');
};

$(() => {
  $('#push').on('click', () => {
    addTx();
  });
  $('#reload').on('click', () => {
    reload();
  });
});

/*
setInterval(() => {
  addTx();
  addTx();
  addTx();
}, 2000);
*/


const init = () => {
  web3.eth.defaultAccount = userName;
  const table = $('#list')[0];
  for (var i = 0, len = CounterAddressList.length; i < len; i++) {
    // カウンターContractを取得
    const counter = web3.eth.contract(counerABI).at(CounterAddressList[i]);
    const row = table.insertRow();
    const td = row.insertCell(0);
    const radioButton1 = document.createElement('input');
    radioButton1.type = 'radio';
    radioButton1.name = 'counter-address';
    radioButton1.value = CounterAddressList[i];
    td.appendChild(radioButton1);

    const td1 = row.insertCell(1);
    td1.innerHTML = web3.toAscii(counter.getCounterName());

    const td2 = row.insertCell(2);
    td2.innerHTML = counter.getNumberOfCounter();
  }
};

const refresh = () => {
  web3.eth.defaultAccount = userName;
  const table = $('#list')[0];
  table.innerHTML = '<tr><th></th><th>name</th><th>count</th></tr>';

  init();
};

/**
 * カウントアップ
 */
const countUp = () => {
  web3.eth.defaultAccount = userName;
  let targetAddress;
  const CounterList = document.getElementsByName('counter-address');
  for (var i = 0, len = CounterList.length; i < len; i++) {
    if(CounterList[i].checked){
      targetAddress = CounterList[i].value;
    }
  }

  // 対象のContractを取得
  const counter = web3.eth.contract(counerABI).at(targetAddress);
  counter.countUp();
};

const createJSONdata = (method, params) => {
  const json = {
    jsonrpc: "2.0",
    id: null,
    method: method,
    params: params
  };
  return json;
};

const executeJsonRpc = (url, json, s, e) => {
  $.ajax({
    type: 'post',
    url: url,
    data: JSON.stringify(json),
    contentType: 'application/JSON',
    dataType: 'JSON',
    scriptCharset: 'utf-8'
  }).done((data) => {
    s(data);
  }).fail((data) => {
    e(data);
  });
};





