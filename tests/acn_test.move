#[test_only]
module AptCoin::acn_tests {
    use aptos_framework::account;

    // Test initializing the module
    fun test_init_module() {
        let alice = account::create_account();
        AptCoin::acn.init_module(&alice);
        assert(coin::is_coin_initialized<AptCoin::acn::ACN>(), "Coin should be initialized.");
    }

    // Test registering an account
    fun test_register_account() {
        let bob = account::create_account();
        AptCoin::acn.register(&bob);
        assert(coin::is_account_registered<AptCoin::acn::ACN>(account::address_of(&bob)), "Bob's account should be registered.");
        assert(exists<AptCoin::acn::ACNEventStore>(account::address_of(&bob)), "Bob's event store should exist.");
    }

    // Test minting coins
    fun test_mint_coin() {
        let alice = account::create_account();
        let bob = account::create_account();
        AptCoin::acn.mint_coin(&alice, account::address_of(&bob), 100);
        assert(coin::balance_of<AptCoin::acn::ACN>(account::address_of(&bob)) == 100, "Bob's balance should be 100.");
    }
// Test emitting an event
fun test_event_emission() {
    let bob = account::create_account();
    AptCoin::acn.register(&bob);
    let event_data = event::get_event_data<String>(&AptCoin::acn::ACNEventStore(account::address_of(&bob)).event_handle);
    assert(event_data == "minted ACN", "Event data should be 'minted ACN'.");
}


AptCoin::acn_tests.test_init_module();
AptCoin::acn_tests.test_register();
AptCoin::acn_tests.test_mint_coin();
AptCoin::acn_tests.test_event_emission();

}


