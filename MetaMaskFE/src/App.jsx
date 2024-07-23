import { useState, useEffect } from 'react'
import { Routes, Route, BrowserRouter, useSearchParams } from 'react-router-dom'
import './App.css'
import Web3 from 'web3'

function App() {
  const [count, setCount] = useState(0)

  return (
    <>
      <div>
          <img src="/mmlogo.png" className="logo" alt="MetaMask Logo" />
        <a href="https://numdev.live" target="_blank">
          <img src="/authdev.png" className="logo react" alt="AuthDev Logo" />
        </a>
      </div>
      <BrowserRouter>
        <Routes>
          <Route path='/' element={<Search />} />
        </Routes>
      </BrowserRouter>
      <h1>MetaMask + AuthDev Login</h1>
    </>
  )
}

const Search = () => {
  const [searchParams, setSearchParams] = useSearchParams();

  useEffect(() => {
    const effect = async () => {
      let accounts;
      let web3;
      
      if (!window.ethereum) {
        window.alert('Please install MetaMask first.');
        return;
      }
      try {
        accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        web3 = new Web3(window.ethereum);
      } catch (error) {
        window.alert('You need to allow MetaMask.');
        return;
      }
      if (!accounts) {
        window.alert('Please activate MetaMask first.');
        return;
      }

      const publicAddress = accounts[0].toLowerCase();
      const signature = await web3.eth.personal.sign("I am peer " + searchParams.get("peer") + " requesting to login to AuthDev with authorization " + searchParams.get("authtoken") + " at timestamp " + searchParams.get("timestamp") + ".",publicAddress,'');

      const socket = new WebSocket("ws://localhost:12081")

      socket.addEventListener("open", event => {
        socket.send("Original Message: !" + "I am peer !" + searchParams.get("peer") + "! requesting to login to AuthDev with authorization !" + searchParams.get("authtoken") + "! at timestamp !" + searchParams.get("timestamp") + "!.!" + " Signature: !" + signature + "! Public Address: !" + publicAddress);
      });

    }

    effect();

  }, []);

  return (
    <div>{searchParams.peer}{searchParams.authtoken}{searchParams.timestamp}</div>
  )
}

export default App
