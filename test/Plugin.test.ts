import { expect } from "chai";
import { ethers } from "hardhat";

describe("Plugin", function () {
  it("ValueLimitPlugin.sol", async function () {
    const entryPoint = await (
      await ethers.getContractFactory("EntryPoint")
    ).deploy();
    await entryPoint.deployed();

    const verifier = await (
      await ethers.getContractFactory("Verifier")
    ).deploy();
    await verifier.deployed();
    const fallback = await (
      await ethers.getContractFactory("FallbackHandler")
    ).deploy();
    await fallback.deployed();

    const BaseWallet = await ethers.getContractFactory("BaseWallet");

    const baseWallet = await BaseWallet.deploy();
    await baseWallet.deployed();

    const [owner, bundler] = await ethers.getSigners();

    const initCode = BaseWallet.interface.encodeFunctionData("initialize", [
      verifier.address,
      "0x",
      fallback.address,
      "0x",
    ]);
    const proxy = await (
      await ethers.getContractFactory("Proxy")
    ).deploy(owner.address, entryPoint.address, baseWallet.address, initCode);
    await proxy.deployed();

    const plugin = await (
      await ethers.getContractFactory("ValueLimitPlugin")
    ).deploy();
    await plugin.deployed();

    const wallet = BaseWallet.attach(proxy.address);
    await wallet.installPlugin(
      plugin.address,
      ethers.utils.defaultAbiCoder.encode(
        ["uint256"],
        [ethers.utils.parseEther("0.1")]
      )
    );

    await owner.sendTransaction({
      to: proxy.address,
      value: ethers.utils.parseEther("1"),
    });
    expect(await ethers.provider.getBalance(proxy.address)).to.equal(
      ethers.utils.parseEther("1")
    );

    await wallet.execute(owner.address, ethers.utils.parseEther("0.05"), "0x");
    expect(await ethers.provider.getBalance(proxy.address)).to.equal(
      ethers.utils.parseEther("0.95")
    );
    await expect(
      wallet.execute(owner.address, ethers.utils.parseEther("0.2"), "0x")
    ).to.be.reverted;
  });
});
