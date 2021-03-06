import "./App.css";
import BotBoard from "./components/botBoard.js";
import Header from "./components/header.js";
import PvPV2 from "./components/pvpV2.js";
import Home from "./components/home.js";
import { ChakraProvider, theme } from "@chakra-ui/react";
import { useState } from "react";
import { ticTacToeBot } from "./abi/TicTacToeBot";
import { ticTacToePVP } from "./abi/TicTacToePVP";
import Web3 from "web3";

const web3 = new Web3(Web3.givenProvider);

const contractAddressBot = "0x2b14E03d74142a4C3b33520E885B90d58eDC89Ab";
const contractAddressPVP = "0xcB18294ca62EdF9b7B48D557B8BB7681314B836C";

const ticTacToeBotContract = new web3.eth.Contract(
  ticTacToeBot,
  contractAddressBot,
  {
    gasPrice: "10000000000", // default gas price in wei, 20 gwei in this case
  }
);

const ticTacToePVPContract = new web3.eth.Contract(
  ticTacToePVP,
  contractAddressPVP,
  {
    gasPrice: "10000000000", // default gas price in wei, 20 gwei in this case
  }
);

function App() {
  const [page, setPage] = useState("Home");

  return (
    <ChakraProvider theme={theme}>
      <Header
        web3={web3}
        setPage={(e) => {
          const gameType = e.target.innerHTML;
          setPage(gameType);
        }}
      />
      {page === "Bot" ? (
        <BotBoard web3={web3} contract={ticTacToeBotContract} />
      ) : page === "Player" ? (
        // <PvP web3={web3} contract={ticTacToeContract} />
        <PvPV2 web3={web3} contract={ticTacToePVPContract} />
      ) : (
        <Home />
      )}
    </ChakraProvider>
  );
}

export default App;
