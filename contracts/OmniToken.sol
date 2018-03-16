pragma solidity ^0.4.16;

import "./Owned.sol";


interface TokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _tokenType,
        uint256 _value,
        address _token,
        bytes _extraData
    )public;
}


contract OmniToken is Owned {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 0;
    // 18 decimals is the strongly suggested default, avoid changing it
    // uint256 public totalSupply;
    mapping(uint256 => uint256) public totalSupplies;

    // This creates an array with all balances
    // mapping(address => uint256) public totalBalanceOf;
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    // mapping(address => mapping(address => uint256)) public totalAllowance;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public allowance;
    mapping (address => bool) public frozenAccount;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 tokenType, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 tokenType, uint256 value);

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function OmniToken(
        string tokenName,
        string tokenSymbol
    ) public {
        // totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        // balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param _tokenType the type of the token
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 _tokenType, uint256 mintedAmount) public onlyOwner {
        balanceOf[target][_tokenType] += mintedAmount;
        totalSupplies[_tokenType] += mintedAmount;
        Transfer(0, this, _tokenType, mintedAmount);
        Transfer(this, target, _tokenType, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _tokenType the type of the token
     * @param _value the amount to send
     */
    function transferToken(address _to, uint256 _tokenType, uint256 _value) public {
        _transfer(msg.sender, _to, _tokenType, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _tokenType the type of the token
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _tokenType, uint256 _value)
    public returns (bool success) {
        require(_value <= allowance[_from][msg.sender][_tokenType]);     // Check allowance
        allowance[_from][msg.sender][_tokenType] -= _value;
        _transfer(_from, _to, _tokenType, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _tokenType the type of the token
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _tokenType, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender][_tokenType] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _tokenType the type of the token
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _tokenType, uint256 _value, bytes _extraData)
    public returns (bool success) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _tokenType, _value)) {
            spender.receiveApproval(msg.sender, _tokenType, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _tokenType the type of the token
     * @param _value the amount of money to burn
     */
    function burnToken(uint256 _tokenType, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender][_tokenType] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender][_tokenType] -= _value;            // Subtract from the sender
        totalSupplies[_tokenType] -= _value;                      // Updates totalSupply
        Burn(msg.sender, _tokenType, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _tokenType the type of the token
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _tokenType, uint256 _value) public returns (bool success) {
        require(balanceOf[_from][_tokenType] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender][_tokenType]);    // Check allowance
        balanceOf[_from][_tokenType] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender][_tokenType] -= _value;             // Subtract from the sender's allowance
        totalSupplies[_tokenType] -= _value;                              // Update totalSupply
        Burn(_from, _tokenType, _value);
        return true;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _tokenType, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from][_tokenType] >= _value);
        // Check for overflows
        require(balanceOf[_to][_tokenType] + _value > balanceOf[_to][_tokenType]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from][_tokenType] + balanceOf[_to][_tokenType];
        // Subtract from the sender
        balanceOf[_from][_tokenType] -= _value;
        // Add the same to the recipient
        balanceOf[_to][_tokenType] += _value;
        Transfer(_from, _to, _tokenType, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from][_tokenType] + balanceOf[_to][_tokenType] == previousBalances);
    }
}
