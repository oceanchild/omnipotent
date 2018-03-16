module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    },
    ropsten: {
      network_id: 3,
      host: "127.0.0.1",
      port: 8545,
      gas: 4000000,
      from: "0x6c7a03df2698a04c52d9511bf8f793cc23229e35"
    }
  }
};
