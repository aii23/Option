const { expect } = require("chai");
const { BigNumber } = ethers;


describe("OptionAdministration contract", () => {
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

		Option = await OptionContract.deploy(back.address);
	});

	describe("Price Change", () => {
		it(`Non owner can't change option price`, async () => {
			await expect(Option.connect(addr1).setOptionPrice(optionPrice)).to.be.revertedWith('Ownable: caller is not the owner');
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
});