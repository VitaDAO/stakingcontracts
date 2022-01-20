import { ethers } from "hardhat";
import { BigNumber, Contract, Signer } from "ethers";
import { expect } from "chai";

const {
  BN,           // Big Number support
  constants,    // Common constants, like the zero address and largest integers
  expectEvent,  // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');


const VITA_CAP = ethers.constants.WeiPerEther.mul(BigNumber.from(64298880))

describe('VITA Staking', () => {

  
  let accounts: Signer[];

  let admin: Signer;
  let user1Alice: Signer;
  let user2Bob: Signer;
  let user3Cat: Signer;

  let adminAddress: string;
  let user1AliceAddress: string;
  let user2BobAddress: string;
  let user3CatAddress: string;

  let token: Contract;
  let staking: Contract;

  beforeEach(async function () {
    accounts = await ethers.getSigners();
    admin = accounts[1];
    user1Alice = accounts[2];
    user2Bob = accounts[3];
    user3Cat = accounts[4];

    adminAddress = await admin.getAddress();
    user1AliceAddress = await user1Alice.getAddress();
    user2BobAddress = await user2Bob.getAddress();
    user3CatAddress = await user3Cat.getAddress();

  });

  describe("Staking contract", () => {
    beforeEach(async () => {
        let Token = await ethers.getContractFactory("VITA");
        token = await Token.connect(admin).deploy("VITA Token", "VITA", VITA_CAP);
        await token.deployed();
        let Staking = await ethers.getContractFactory("VITAStaking");
        staking = await Staking.connect(admin).deploy(token.address);
        await staking.deployed();
        expect(await staking.getTokenAddress()).to.equal(token.address);
    });

    describe("Functions", () => {});
      
    
  });
});
