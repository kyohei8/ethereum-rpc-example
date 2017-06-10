const url = 'http://10.0.1.98:8545';
let userName;
let web3;

if (typeof web3 !== 'undefined') {
  web3 = new Web3(web3.currentProvider);
} else {
  // set the provider you want from Web3.providers
  web3 = new Web3(new Web3.providers.HttpProvider(url));
}

web3.eth.defaultAccount = web3.eth.accounts[0];

const counerABI = [{"constant":false,"inputs":[],"name":"countUp","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"getCounterName","outputs":[{"name":"name","type":"bytes32"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"getNumberOfCounter","outputs":[{"name":"number","type":"uint32"}],"payable":false,"type":"function"},{"inputs":[{"name":"name","type":"bytes32"}],"payable":false,"type":"constructor"}]
const counterMasterABI = [{ "constant":true, "inputs":[], "name":"getCounterAddressList","outputs":[{"name":"counterAddressList","type":"address[]"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"name","type":"bytes32"}],"name":"addCounter","outputs":[],"payable":false,"type":"function"}]

// カウンターアドレスリストを取得
const master = web3.eth.contract(counterMasterABI).at('0x7e3d6c7384173a0bb6fb14cf6e9d8691d49494bd');
const CounterAddressList = master.getCounterAddressList();

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
      init();
    } else {
      console.log('login error');
    }
  }, (data) => {
    // fail
    console.log('login error');
  });
};

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





