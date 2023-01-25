module AptCoin::acn{
    use aptos_framework::coin;
    use aptos_framework::event;
    use aptos_framework::account;
    use aptos_std::type_info;
    use std::string::{utf8, String};
    use std::signer;

    struct ACN {} // unique identifier of the coin.

// used to store some capabilities obtained from the aptos_framework::coin module.
    struct CapsStore has key{ 
        mint_cap: coin::MintCapability<ACN>,
        freeze_cap: coin::FreezeCapability<ACN>,
        burn_cap: coin::BurnCapability<ACN>
    }

//used for recording user events.
    struct ACNEventStore has key{
        event_handle: event::EventHandle<String>,
    }

//used to initialize the module and will only be called once when the module is published on the chain. 
//the module calls coin::initialize<ACN>.
// it register the AptCoin::acn::ACN as a unique identifier for a new coin.
    fun init_module(account: &signer){
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<ACN>(account, utf8(b"ACN"), utf8(b"ACN"), 6, true);
        move_to(account, CapsStore{mint_cap: mint_cap, freeze_cap: freeze_cap, burn_cap: burn_cap});
    }

//It is used to help users register coin usage rights and event recorders.
//aptos_framework::coin module stipulates that the user has to first explicitly register the right to use the coin
// through the aptos_framework::coin::register function.
//The registration puts a CoinStore struct into account. 
//CoinStore struct contains a Coin struct to record balance.
    public entry fun register(account: &signer){
        let address_ = signer::addres_of(account);
        if(!coin::is_account_registered<ACN>(address_)){
            coin::register<ACN>(account);
        };
        if(!exists<ACNEventStore>(address_)){
            move_to(account, ACNEventStore{event_handle: account::new_event_handle(account)});
        };
    }

    fun emit_event(account: address, msg: String) acquires ACNEventStore{
        event::emit_event<String>(&mut borrow_global_mut<ACNEventStore>(account).event_handle, msg);
    }

//the mint_coin function is used to mint coins
//only admins can mint coins
//need to verify the corresponding capability in this function.
    public entry fun mint_coin(cap_owner: &signer, to_address: address, amount: u64) acquires CapStore, ACNEventStore{
//cap_owner is of type &signer, i.e., the initiator of the transaction.
//to_address indicates the address to which the minted coins will be deposited.
//amount indicates the number of coins being minted.
        let mint_cap = &borrow_global<CapStore>(signer::address_of(cap_owner)).mint_cap;
//borrow_global<CapStore> is used to confirm whether the account owns CapStore
// it is to verify admin of the module
//it can guarantee that only the admin can mint coins
        let mint_coin = coin::mint<ACN>(amount, mint_cap);
//mint_coin function will then invoke the mint function of the aptos_framework::coin module.
// it mint coins.
//a parameter named _cap is required to be passed as a reference of MintCapability.
        coin::deposit<ACN>(to_address, mint_coin);
// the mint_coin function will invoke the deposit function.
//it deposit the minted coins to the specified to_address.
        emit_event(to_address, utf8(b"minted ACN"));
    }

//any user can invoke the burn_coin function.
//account is of type &signer, i.e., the initiator of the transaction.
//amount indicates the number of coins being burnt.
//burn function of the aptos_framework::coin module requires the caller.
//it allows to pass in a reference to BurnCapability
    public entry fun burn_coin(account: &signer, amount: u64) acquires CapStore, ACNEventStore{
        let owner_address = type_info::account_address(&type_info::type_of<ACN>());
//borrow_global is used to read a particular data type from the immutable global storage of an account.
//It allows a module to lend the capability owned by the admin to other users.
        let burn_cap = &borrow_global<CapStore>(owner_address).burn_cap;
//initiator of the burn_coin function is the user rather than the admin.
//So, admin address cannot be obtained through signer but
// it can be obtained through aptos_std::type_info
//with ACN to get the module's address where this structure is defined.
        let burn_coin = coin::withdraw<ACN>(account, amount);
//After getting the BurnCapability, 
//the module can withdraw the coin of the specified amount from the user 
//and burn the coin with that capability.
        coin::burn<ACN>(burn_coin, burn_cap);
        emit_event(signer::address_of(account), utf8(b"burned ACN"));
    }

//freeze_self function for users to freeze their coin accounts
    public entry fun freeze_self(account: &signer) acquires CapStore, ACNEventStore{
        let owner_address = type_info::account_address(&type_info::type_of<ACN>());
        let freeze_cap = &borrow_global<CapStore>(owner_address).freeze_cap;
        let freeze_address = signer::address_of(account);
        coin::freeze_coin_store<ACN>(freeze_address, freeze_cap);
        emit_event(freeze_address, utf8(b"freezed self"));
    }

//emergency_freeze function for emergency freezing
//It can only be used by the admin.
     public entry fun emergency_freeze(cap_owner: &signer, freeze_address: address) acquires CapStore, ACNEventStore{
        let owner_address = signer::address_of(cap_owner);
        let freeze_cap = &borrow_global<CapStore>(owner_address).freeze_cap;
        coin::freeze_coin_store<ACN>(freeze_address, freeze_cap);
        emit_event(freeze_address, utf8(b"emergency freezed"));
    }

//unfreeze function also requires the admin to unfreeze the user accounts.
    public entry fun unfreeze(cap_owner: &signer, unfreeze_address: address) acquires CapStore, ACNEventStore{
        let owner_address = signer::address_of(cap_owner);
        let freeze_cap = &borrow_global<CapStore>(owner_address).freeze_cap;
        coin::unfreeze_coin_store<ACN>(unfreeze_address, freeze_cap);
        emit_event(unfreeze_address, utf8(b"unfreezed"));
    }

    public entry fun transfer<CoinType>(
        from: &signer,
        to: address,
        amount: u64,
    ) acquires CoinStore {
//withdraw function requires the &signer permission
//It is used to withdraw a certain amount of assets from your account into a coin
        let coin = withdraw<CoinType>(from, amount);
//deposit function can deposit a coin into any registered account of the coin
        deposit(to, coin);
// the transferred coins will be automatically merged with the coins stored in the CoinStore struct of the target address.
    }

//extract function is used to split coins
//It receives a Coin struct
// extracts a part of the asset in it to generate a new Coin struct
    public fun extract<CoinType>(coin: &mut Coin<CoinType>, amount: u64): Coin<CoinType> {
        assert!(coin.value >= amount, error::invalid_argument(EINSUFFICIENT_BALANCE));
        coin.value = coin.value - amount;
        Coin { value: amount }
    }

//extract_all function is used to extract the entire value of the original Coin struct
//and it deposit it into a new Coin struct
    public fun extract_all<CoinType>(coin: &mut Coin<CoinType>): Coin<CoinType> {
        let total_value = coin.value;
        coin.value = 0;
        Coin { value: total_value }
    }

//As a result, the value of the original Coin struct will become zero (aka zero_coin).
//zero_coin struct can be destroyed by invoking the destroy_zero function.
    public fun destroy_zero<CoinType>(zero_coin: Coin<CoinType>) {
        let Coin { value } = zero_coin;
        assert!(value == 0, error::invalid_argument(EDESTRUCTION_OF_NONZERO_TOKEN))
    }

//merge function is used to merge coins
//It can merge the value of two Coin structs
//eg. source_coin and dst_coin, into the dst_coin struct and destroy the source_coin struct.
    public fun merge<CoinType>(dst_coin: &mut Coin<CoinType>, source_coin: Coin<CoinType>) {
        spec {
            assume dst_coin.value + source_coin.value <= MAX_U64;
        };
        dst_coin.value = dst_coin.value + source_coin.value;
        let Coin { value: _ } = source_coin;
    }

//zero function is used to generate a zero_coin struct.
    public fun zero<CoinType>(): Coin<CoinType> {
        Coin<CoinType> {
            value: 0
        }
    }
}