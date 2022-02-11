




describe("Option contract", () => {
	let OptionContract;
	let Option;
	let owner;
	let addr1;
	let addr2; 
	let addr3;
	let addrs; 

	beforeEach(async () => {
		OptionContract = await ethers.getContractFactory("Token");
		[owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

		Option = await OptionContract.deploy();
	});

	describe("Liquidity tests", () => {

	});

	describe("Option tests", () => {

	});
});