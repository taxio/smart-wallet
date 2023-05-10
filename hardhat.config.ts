import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  gasReporter: {
    enabled: !!process.env.REPORT_GAS,
    currency: "USD",
    token: process.env.GAS_REPORTER_TOKEN,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
  }
};

export default config;
