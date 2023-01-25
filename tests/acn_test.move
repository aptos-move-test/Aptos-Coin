#[test_only]
module AptCoin::acn_tests {
    use aptos_framework::account;

   // Test initializing the module
// public fun test_init_module(){
//     let ashish = account::create_account();
//     AptCoin::acn.init_module(&ashish);
//     assert(coin::is_coin_initialized<AptCoin::acn::ACN>(), "Coin should be initialized.");
// }

// Test registering an account
public fun test_register(){
    let amrit = account::create_account();
    AptCoin::acn.register(&amrit);
    assert(coin::is_account_registered<AptCoin::acn::ACN>(account::address_of(&amrit)), "amrit's account should be registered.");
    assert(exists<AptCoin::acn::ACNEventStore>(account::address_of(&amrit)), "amrit's event store should exist.");
}

// Test minting coins
public fun test_mint_coin(){
    let ashish = account::create_account();
    let amrit = account::create_account();
    AptCoin::acn.register(&amrit);
    AptCoin::acn.mint_coin(&ashish, account::address_of(&amrit), 100);
    assert(coin::balance_of<AptCoin::acn::ACN>(account::address_of(&amrit)) == 100, "amrit's balance should be 100.");
}

// Test emitting an event
public fun test_emit_event(){
    let ashish = account::create_account();
    let amrit = account::create_account();
    AptCoin::acn.register(&amrit);
    AptCoin::acn.mint_coin(&ashish, account::address_of(&amrit), 100);
    let event_data = event::get_event_data<String>(&AptCoin::acn::ACNEventStore(account::address_of(&amrit)).event_handle);
    assert(event_data == "minted ACN", "Event data should be 'minted ACN'.");
}

}
