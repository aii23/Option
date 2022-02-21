require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-solhint");
require('solidity-coverage');
require('hardhat-docgen');
require('dotenv').config();


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
 	solidity: "0.8.1",
 	networks: {
  		hardhat: {
    		forking: {
      			url: `https://mainnet.infura.io/v3/${ process.env.INFURA_KEY }`,
    		}
  		}, 

	}
};
