require("@nomiclabs/hardhat-waffle");

let infuraKey = "2ca...";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
 	solidity: "0.8.1",
 	networks: {
  		hardhat: {
    		forking: {
      			url: `https://mainnet.infura.io/v3/${ infuraKey }`,
    		}
  		}
	}
};
