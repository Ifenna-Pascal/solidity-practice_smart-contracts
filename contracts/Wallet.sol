// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TransactionType { Transfer, Withdrawal, Deposit}

struct Transaction {
    uint txId;
    TransactionType txType;
    address payable txFrom;
    address payable txTo;
    uint txGasPrice;
    uint txAmount;
    uint txBalance;
    uint txDate;
}

struct Wallet_details {
    address payable owner;
    uint balance;
    mapping( uint => Transaction) transactionHistory;
    uint Transaction_count;
}

struct user_wallets {
    uint wallet_count;
    mapping (uint => Wallet_details) owner_wallets;
}

struct Wallet_data {

    mapping (address => user_wallets) users_wallet_collection;
    address[] available_userwallets;
}


contract Wallet {
    event created_wallet(address owner, uint user_created_wallet);
    Wallet_data private _data;

    function create_wallet  () public returns (uint){
        user_wallets storage wallets_of_user = _data.users_wallet_collection[msg.sender];
        wallets_of_user.wallet_count ++;
        wallets_of_user.owner_wallets[wallets_of_user.wallet_count].owner = payable (msg.sender);
        _data.available_userwallets.push(msg.sender);
        emit created_wallet (msg.sender, wallets_of_user.wallet_count );
        return _data.available_userwallets.length;
    }

    function index_of_user (address key) public view returns (int index) {
        for ( uint i = 0; i<= _data.available_userwallets.length; i ++) {
            if(_data.available_userwallets[i] == key) {
                return int(i);
            }
        }
        return -1;
    }

    modifier user_exsits  {
        require(index_of_user(msg.sender) != -1 , "User does not exist");
        _; 
    }    

    function contractBalance() public view returns (uint balance) {
        return address(this).balance;
    }

    function number_of_user_walets () public view user_exsits returns (uint) {
        if(_data.users_wallet_collection[msg.sender].wallet_count > 0) {
            return _data.users_wallet_collection[msg.sender].wallet_count;
        }else {
            return 0;
    }  

    }

    function fundWallet ( uint wallet_id) public payable user_exsits returns (Transaction memory transaction) {
        user_wallets storage wallets_of_user = _data.users_wallet_collection[msg.sender];
        require( wallet_id <= wallets_of_user.wallet_count, "Wallet does not exist");
        wallets_of_user.owner_wallets[wallet_id].balance += msg.value;
        wallets_of_user.owner_wallets[wallet_id].Transaction_count++;
        wallets_of_user.owner_wallets[wallet_id].transactionHistory[wallets_of_user.owner_wallets[wallet_id].Transaction_count] = 
        Transaction (
            wallets_of_user.owner_wallets[wallet_id].Transaction_count,
            TransactionType.Deposit,
            payable (msg.sender),
            wallets_of_user.owner_wallets[wallet_id].owner,
            tx.gasprice,
            msg.value,
            wallets_of_user.owner_wallets[wallet_id].balance,
            block.timestamp
        );

        return wallets_of_user.owner_wallets[wallet_id].transactionHistory[wallets_of_user.owner_wallets[wallet_id].Transaction_count];
    }

    function withdrawFund (uint amount, uint wallet_id) public returns (Transaction memory transaction) {
        user_wallets storage wallets_of_user = _data.users_wallet_collection[msg.sender];
        require( wallet_id <= wallets_of_user.wallet_count, "Wallet does not exist");
        Wallet_details storage wallet_of_user = wallets_of_user.owner_wallets[wallet_id];
        require( wallet_of_user.balance >= amount, "Amount to be withdrawn exceed balance");
        wallet_of_user.balance -= amount; 
        wallet_of_user.Transaction_count ++;
        wallet_of_user.transactionHistory[wallet_of_user.Transaction_count] = Transaction(
            wallet_of_user.Transaction_count,
            TransactionType.Withdrawal,
            payable (msg.sender),
            wallet_of_user.owner,
            tx.gasprice,
            amount,
            wallet_of_user.balance,
            block.timestamp
        );
        wallet_of_user.owner.transfer(amount);
        return wallet_of_user.transactionHistory[wallet_of_user.Transaction_count];
    }

    function withdrawAllFunds (uint wallet_id) public returns (Transaction memory transaction) {
        user_wallets storage wallets_of_user = _data.users_wallet_collection[msg.sender];
        require( wallet_id <= wallets_of_user.wallet_count, "Wallet does not exist");
        Wallet_details storage wallet_of_user = wallets_of_user.owner_wallets[wallet_id];
        uint amount = wallet_of_user.balance;
        require(amount > 0, "No fund is available here");
        wallet_of_user.balance = 0; 
        wallet_of_user.Transaction_count ++;
        wallet_of_user.transactionHistory[wallet_of_user.Transaction_count] = Transaction(
            wallet_of_user.Transaction_count,
            TransactionType.Withdrawal,
            payable (msg.sender),
            wallet_of_user.owner,
            tx.gasprice,
            amount,
            wallet_of_user.balance,
            block.timestamp
        );
        wallet_of_user.owner.transfer(amount);
        return wallet_of_user.transactionHistory[wallet_of_user.Transaction_count];
    }

    function transferFund (address payable _to, uint amount, uint wallet_id) public returns (Transaction memory transaction) {
        user_wallets storage wallets_of_user = _data.users_wallet_collection[msg.sender];
        // require( wallet_id <= wallets_of_user.wallet_count, "Wallet does not exist");
        Wallet_details storage wallet_of_user = wallets_of_user.owner_wallets[wallet_id];
        require( wallet_of_user.balance >= amount, "Amount to be withdrawn exceed balance");
        wallet_of_user.balance -= amount; 
        wallet_of_user.Transaction_count ++;
        wallet_of_user.transactionHistory[wallet_of_user.Transaction_count] = Transaction(
            wallet_of_user.Transaction_count,
            TransactionType.Transfer,
            payable (msg.sender),
            _to,
            tx.gasprice,
            amount,
            wallet_of_user.balance,
            block.timestamp
        );
        _to.transfer(amount);
        return wallet_of_user.transactionHistory[wallet_of_user.Transaction_count];
    }

    function viewAccountBalance ( uint wallet_id ) public view user_exsits returns (uint balance) {
        user_wallets storage wallets_of_user = _data.users_wallet_collection[msg.sender];
        require( wallet_id <= wallets_of_user.wallet_count, "Wallet does not exist");
        return wallets_of_user.owner_wallets[wallet_id].balance;
    }


}
