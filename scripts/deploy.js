const hre = require("hardhat");

async function main() {
  console.log("Deploying DAOVoting contract...");

  // Get contract factory
  const DAOVoting = await hre.ethers.getContractFactory("DAOVoting");

  // Deploy contract
  const daoVoting = await DAOVoting.deploy();
  await daoVoting.waitForDeployment();

  // Get the deployed contract address
  const address = await daoVoting.getAddress();
  console.log(`DAOVoting deployed to: ${address}`);
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
