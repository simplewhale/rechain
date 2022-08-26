import React, { Component } from 'react'
import SimpleStorageContract from '../build/contracts/bank.json'
import getWeb3 from './utils/getWeb3'

import './css/oswald.css'
import './css/open-sans.css'
import './css/pure-min.css'
import './App.css'


const contractAddress = "0x8371fca0b9c8978a9aa63b5b9f5cde3f5ddfcd5f"; // 合约地址
var simpleStorageInstance;// 合约实例


class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      storageValue: 0,
      web3: null,
      amount:0,
      _totalsupply:0,
      introduce:"",
      num:"",
      c_address:"",
      _length:"",
      _contents:[]
    }
  }

  componentWillMount() {
    // Get network provider and web3 instance.
    // See utils/getWeb3 for more info.

    getWeb3
    .then(results => {
      this.setState({
        web3: results.web3
      })

      // Instantiate contract once web3 provided.
      this.instantiateContract()
    })
    .catch(() => {
      console.log('Error finding web3.')
    })
  }

  instantiateContract() {
    /*
     * SMART CONTRACT EXAMPLE
     *
     * Normally these functions would be called in the context of a
     * state management library, but for convenience I've placed them here.
     */

    const contract = require('truffle-contract')
    const simpleStorage = contract(SimpleStorageContract)
    simpleStorage.setProvider(this.state.web3.currentProvider)



    // Get accounts.
    this.state.web3.eth.getAccounts((error, accounts) => {
      console.log(accounts[0]);
      this.setState({
            _address: accounts[0]
      })
      simpleStorage.at(contractAddress).then((instance) => {
        simpleStorageInstance = instance
        return;
      }).then((result)=>{
        simpleStorageInstance.contents_length.call().then((result)=>{
            this.setState({_length: result.c[0]})
      })}).then((result1)=>{
        simpleStorageInstance.totalsupply.call().then((result1)=>{
          this.setState({_totalsupply: result1.c[0]})
        })
      }).then((result2) => {
        // Get the value from the contract to prove it worked.
          return simpleStorageInstance.contents;
      }).then((result2)=>{
        const requests = [];
         for(let u = 0; u<=this.state._length ;u++)
                {
                  result2(u).then(function(result){
                      requests.push(result);
                  //    console.log(result);
                  })
                }
                this.setState({
              _contents:requests
            })
              console.log(this.state._contents);
      })
    })
  }

  isNumber(e) {
  this.setState({
    amount: e.target.value
  });
  }

  isNumber1(e) {
  this.setState({
    introduce: e.target.value
  });
  }
  isNumber2(e) {
  this.setState({
    num: e.target.value
  });
  }
  isNumber3(e) {
  this.setState({
    c_address: e.target.value
  });
  }

  getInvestment(){
    simpleStorageInstance.investment({from:this.state.web3.eth.accounts[0],value: this.state.web3.toWei(this.state.amount,"ether")}).then((result)=>{
      console.log("投资成功");
    })
  }

  Change_state(){
      simpleStorageInstance.recognition();
    }

  add_project(){
        simpleStorageInstance.project(this.state.introduce,this.state.num,this.state.c_address).then(()=>{
          console.log("add 成功");
        });
      }

_withdrawals(){
    simpleStorageInstance.withdrawals().then(()=>{
      console.log("获得投资");
    });
}

  render() {
    return (
      <div className="App">
        <nav className="navbar pure-menu pure-menu-horizontal">
            <a href="#" className="pure-menu-heading pure-menu-link">Truffle Box</a>
        </nav>

        <main className="container">
              <div>
              <p>{this.state._length}</p>
              <table className="tableRanking">
                {
                  this.state._contents.map((object) => {

                    return (
                      <tr>
                        <td>{object[0].c[0]}</td>
                        <td>{object[1]}</td>
                        <td>{object[2]}</td>
                        <td>{object[3].c[0]}</td>
                        <td>{object[4]}</td>
                        <td>{object[5]}</td>
                        <td>  <button onClick={()=>this._withdrawals()}>提款</button> </td>
                      </tr>
                    )
                  })
                }
            </table>
              </div>


          <div className="pure-g">
            <div className="pure-u-1-1">
              <h1>Good to Go!</h1>
              <p>Your Truffle Box is installed and ready.</p>
              <h2>Smart Contract Example</h2>
              <p>If your contracts compiled and migrated successfully, below will show a stored value of 5 (by default).</p>
              <p>Try changing the value stored on <strong>line 59</strong> of App.js.</p>
              <p>The stored value is: {this.state._totalsupply}</p>
                <p>The stored value is: {this.state._length}</p>
            </div>
          </div>
          <div>
          <input type="text" value={this.state.amount} className="select" onChange={e => this.isNumber(e)} placeholder="输入投资数目" />
          <button onClick={()=>this.getInvestment()}>投资合约</button>

          </div>
          <div>
              <input type="text" value={this.state.introduce} className="select" onChange={e => this.isNumber1(e)} placeholder="项目介绍" />项目介绍
              <input type="text" value={this.state.num} className="select" onChange={e => this.isNumber2(e)} placeholder="项目所需资金" />项目所需资金
              <input type="text" value={this.state.c_address} className="select" onChange={e => this.isNumber3(e)} placeholder="项目合约地址" />项目合约地址
                <button onClick={()=>this.add_project()}>添加项目</button>
          </div>
        </main>
      </div>
    );
  }
}

export default App
