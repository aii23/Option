const { expect } = require("chai");
const { BigNumber } = ethers;

const DAI_ADDRESS = '0x6b175474e89094c44da98b954eedeac495271d0f';

const toBytes32 = (bn) => {
  return ethers.utils.hexlify(ethers.utils.zeroPad(bn.toHexString(), 32));
};

function findPosition(address) {
	const slot = 2; // For DAI

	return ethers.utils.solidityKeccak256(
    	["uint256", "uint256"],
    	[address, slot] // key, slot
	) 
}

async function setDAIBalance(address, balance) {
	let position = findPosition(address);

	await network.provider.send("hardhat_setStorageAt", 
	[
		DAI_ADDRESS,
		position,
		toBytes32(ethers.BigNumber.from(balance)).toString()
	])
}


describe("Option contract", () => {
	let DAIContract;
	let DAI;
	let OptionContract;
	let Option;
	let owner;
	let addr1;
	let addr2; 
	let back;
	let addrs; 
	let firstAddresses;

	let tokenBase =  BigNumber.from(10).pow(18);
	let initialDAIBalance = tokenBase.mul(1000000);
	let optionPrice = tokenBase.mul(100);

	let ethPrice = tokenBase.mul(2000);

	beforeEach(async () => {
		OptionContract = await ethers.getContractFactory("Option");
		[owner, addr1, addr2, back, ...addrs] = await ethers.getSigners();
		firstAddresses = [owner, addr1, addr2, back];

		// console.log(addr1.address);

		// const addr1Balance = 1000000;

		Option = await OptionContract.deploy(back.address);
		DAI = await ethers.getContractAt("IERC20", DAI_ADDRESS);

		firstAddresses.forEach(async (addr) => {
			setDAIBalance(addr.address, initialDAIBalance);
		});


		// console.log(addr1.address);
		// setDAIBalance(addr1.address, addr1Balance);

		// console.log(await DAI.balanceOf(addr1.address));

		// expect(await DAI.balanceOf(addr1.address)).to.equal(addr1Balance);
	});

	describe("Initial checks", () => {
		it("Correct initial DAI balances", async () => {
			firstAddresses.forEach(async (addr) => {
				expect(await DAI.balanceOf(addr.address)).to.equal(initialDAIBalance);
			});
		});
	});

	describe("Basic liquidity tests", () => {
		it("Owner can add/remove liquidity", async () => {
			const DAIBalance = initialDAIBalance;
			const addedLiquidity = tokenBase.mul(1000);
			const removedLiquidity = tokenBase.mul(500);

			// Approve DAi tokens for contract
			await DAI.approve(Option.address, DAIBalance);
			// Add liquidity
			await Option.addLiquidity(addedLiquidity);

			expect(await Option.totalSupply()).to.equal(addedLiquidity);
			expect(await DAI.balanceOf(owner.address)).to.equal(DAIBalance.sub(addedLiquidity));

			// Remove liquidity
			await Option.removeLiquidity(removedLiquidity); 

			expect(await Option.totalSupply()).to.equal(addedLiquidity.sub(removedLiquidity));
			expect(await DAI.balanceOf(owner.address)).to.equal(DAIBalance.sub(addedLiquidity).add(removedLiquidity));
		});

		it("Non-owner can't add/remove liquidity", async () => {
			const DAIBalance = initialDAIBalance;
			const addedLiquidity = tokenBase.mul(1000);
			const removedLiquidity = tokenBase.mul(500);
			// Approve DAi tokens for contract
			await DAI.approve(Option.address, DAIBalance);
			await Option.addLiquidity(addedLiquidity);

			await expect(Option.connect(addr1).addLiquidity(addedLiquidity)).to.be.revertedWith('Only owner');
			await expect(Option.connect(addr1).removeLiquidity(removedLiquidity)).to.be.revertedWith('Only owner');
		});
	});

	describe("Price Change", () => {
		it(`Non owner can't change option price`, async () => {
			await expect(Option.connect(addr1).setOptionPrice(optionPrice)).to.be.revertedWith('Only owner');
		});

		it(`Owner can change option price`, async () => {
			await Option.setOptionPrice(optionPrice);
			expect(await Option.optionPrice()).to.equal(optionPrice);
		});

		it(`Non back can't change ether price`, async () => {
			await expect(Option.setPrice(ethPrice)).to.be.revertedWith('Only back');
		});

		it(`Back can change ether price`, async () => {
			await Option.connect(back).setPrice(ethPrice);
			expect(await Option.price()).to.equal(ethPrice);
		});
	});

	describe("Option tests", () => {
		let initialLiquidity = tokenBase.mul(100000);


		beforeEach(async () => {
			// Set Option price
			await Option.setOptionPrice(optionPrice);
			// Set eth price
			await Option.connect(back).setPrice(ethPrice);
			// Add liquidity
			await DAI.approve(Option.address, initialDAIBalance);
			await Option.addLiquidity(initialLiquidity);
		});

		it(`Can't buy option with lower price`, async () => {
			let userPrice = optionPrice.sub(1); // Price for 1 ether - 1
			let amount = BigNumber.from(10).pow(18); // 1 ether 

			await DAI.connect(addr1).approve(Option.address, userPrice);

			// console.log(amount);

			await expect(Option.connect(addr1).buyEthPutOption(amount)).to.be.revertedWith(`VM Exception while processing transaction: reverted with reason string 'Dai/insufficient-allowance'`);

		});

		it(`Can't buy uncovered option`, async () => {
			let amount = initialLiquidity.div(ethPrice).mul(tokenBase).add(1);

			await expect(Option.connect(addr1).buyEthPutOption(amount)).to.be.revertedWith(`VM Exception while processing transaction: reverted with reason string 'Can't produce such amount of options'`);
		});

		it(`Can buy covered option with right price`, async () => {
			let price = optionPrice;
			let amount = tokenBase;

			let prevLastOptionId = await Option.lastOptionId();

			await DAI.connect(addr1).approve(Option.address, price);
			await Option.connect(addr1).buyEthPutOption(amount); 

			expect(await Option.totalDebt()).to.equal(ethPrice);
			expect(await Option.lastOptionId()).to.equal(prevLastOptionId.add(1));
		});

		it(`Can't remove liquidity, so option become uncovered`, async () => {
			let price = optionPrice;
			let amount = tokenBase;

			let prevLastOptionId = await Option.lastOptionId();

			await DAI.connect(addr1).approve(Option.address, price);
			await Option.connect(addr1).buyEthPutOption(amount);

			await expect(Option.removeLiquidity(initialLiquidity)).to.be.revertedWith(`You should cover debt`);
		});

		it(`Can't release option you don't own`, async () => {
			let price = optionPrice;
			let amount = tokenBase;

			let prevLastOptionId = await Option.lastOptionId();

			await DAI.connect(addr1).approve(Option.address, price);
			let txData = await Option.connect(addr1).buyEthPutOption(amount);
			let optionId = txData.value;

			await expect(Option.connect(addr2).releasePutOption(optionId)).to.be.revertedWith(`You can't release option you don't own`);
		});

		it(`Can't release option on wrong time`, async () => {
			let price = optionPrice;
			let amount = tokenBase;

			let prevLastOptionId = await Option.lastOptionId();

			await DAI.connect(addr1).approve(Option.address, price);
			let txData = await Option.connect(addr1).buyEthPutOption(amount);
			let optionId = txData.value;

			let day = 60 * 60 * 24; // 1 day

			await network.provider.send("evm_increaseTime", [day]);
			await network.provider.send("evm_mine"); 

			await expect(Option.connect(addr1).releasePutOption(optionId, { value: amount })).to.be.revertedWith(`Option is not in oportunity window`);

			let week = 60 * 60 * 24 * 7; 

			await network.provider.send("evm_increaseTime", [week + 1]);
			await network.provider.send("evm_mine"); 

			await expect(Option.connect(addr1).releasePutOption(optionId, { value: amount })).to.be.revertedWith(`Option is not in oportunity window`);
		});

		it(`Can't use option to sell more ether`, async () => {
			let price = optionPrice;
			let amount = tokenBase;

			let prevLastOptionId = await Option.lastOptionId();

			await DAI.connect(addr1).approve(Option.address, price);
			let txData = await Option.connect(addr1).buyEthPutOption(amount);
			let optionId = txData.value;

			let week = 60 * 60 * 24 * 7; 

			await network.provider.send("evm_increaseTime", [week + 1]);
			await network.provider.send("evm_mine"); 

			await expect(Option.connect(addr1).releasePutOption(optionId, { value: amount + 1 })).to.be.revertedWith(`Wrong ether value`);
		});

		it(`Can release option`, async () => {
			let price = optionPrice;
			let amount = tokenBase; // 1 eth

			let prevLastOptionId = await Option.lastOptionId();

			await DAI.connect(addr1).approve(Option.address, price);
			let txData = await Option.connect(addr1).buyEthPutOption(amount);
			let optionId = txData.value;

			let week = 60 * 60 * 24 * 7; 

			await network.provider.send("evm_increaseTime", [week]);
			await network.provider.send("evm_mine"); 

			let balanceBeforeRelease = await DAI.balanceOf(addr1.address);

			await Option.connect(addr1).releasePutOption(optionId, { value: amount });

			let balanceAfterRelease = await DAI.balanceOf(addr1.address);

			expect(balanceBeforeRelease.add(ethPrice)).to.equal(balanceAfterRelease);
		})
	});
});