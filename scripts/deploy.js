async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const OptionContract = await ethers.getContractFactory("Option");
  // back = deployer
  const Option = await OptionContract.deploy(deployer.address);

  console.log("Option address:", Option.address);

  console.log("Wait 2 minute before verification");

  await new Promise(r => setTimeout(r, 120000));

  console.log("Verification started");

  await hre.run("verify:verify", {
    address: Option.address,
    constructorArguments: [ deployer.address ],
  });

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
