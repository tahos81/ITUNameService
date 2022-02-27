const main = async () => {
    const domainContractFactory = await hre.ethers.getContractFactory('Domains');
    const domainContract = await domainContractFactory.deploy("itu");
    await domainContract.deployed();
  
    console.log("Contract deployed to:", domainContract.address);
  
    
    let txn = await domainContract.register("tahir", {value: hre.ethers.utils.parseEther('0.1'), maxFeePerGas:10000000000, gasLimit:80e5,});
    await txn.wait();
    console.log("Minted domain tahir.itu");
  
    txn = await domainContract.setRecord("tahir", "CRN: 040170046");
    await txn.wait();
    console.log("Set record for tahir.itu");
  
    const address = await domainContract.getAddress("tahir");
    console.log("Owner of domain tahir:", address);
  
    const balance = await hre.ethers.provider.getBalance(domainContract.address);
    console.log("Contract balance:", hre.ethers.utils.formatEther(balance));
  }
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();