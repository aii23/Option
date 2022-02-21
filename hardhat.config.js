require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-solhint");
require("@nomiclabs/hardhat-etherscan");
require('solidity-coverage');
require('hardhat-docgen');
require('dotenv').config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
 	solidity: {
    	version: "0.8.1",
    	settings: {
      		optimizer: {
        		enabled: true,
        		runs: 20000
      		}
    	}
  	},
 	networks: {
  		hardhat: {
    		forking: {
      			url: `https://mainnet.infura.io/v3/${ process.env.INFURA_KEY }`,
    		}
  		}, 
  		rinkeby: {
  			url: `https://rinkeby.infura.io/v3/${ process.env.INFURA_KEY }`, 
  			accounts: [ process.env.RINKEBY_PRIVATE_KEY ]
  		}
	},
	etherscan: {
		apiKey: process.env.ETHERSCAN_KEY
	}
};
