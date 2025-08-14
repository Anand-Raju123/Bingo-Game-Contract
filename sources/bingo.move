module anand_addr::BingoGame {
    use aptos_framework::timestamp;
    use std::vector;
    use std::signer;
    
    const E_GAME_ALREADY_EXISTS: u64 = 1;
    const E_GAME_NOT_ACTIVE: u64 = 2;
    const E_GAME_COMPLETE: u64 = 3;
    const E_UNAUTHORIZED: u64 = 4;
    
    struct Game has store, key {
        numbers_called: vector<u8>,
        called_mask: vector<bool>,
        total_numbers: u8,
        entry_fee: u64,
        prize_pool: u64,
        is_active: bool,
    }
    
    public fun create_game(owner: &signer, entry_fee: u64) {
        let owner_addr = signer::address_of(owner);
        assert!(!exists<Game>(owner_addr), E_GAME_ALREADY_EXISTS);
        
        let mask = vector::empty<bool>();
        let i: u64 = 0;
        while (i < 76) {
            vector::push_back(&mut mask, false);
            i = i + 1;
        };
        
        let game = Game {
            numbers_called: vector[],
            called_mask: mask,
            total_numbers: 0,
            entry_fee,
            prize_pool: 0,
            is_active: true,
        };
        move_to(owner, game);
    }
    
    public fun call_number(caller: &signer, game_owner: address) acquires Game {
        let caller_addr = signer::address_of(caller);
        assert!(caller_addr == game_owner, E_UNAUTHORIZED);
        
        let game = borrow_global_mut<Game>(game_owner);
        assert!(game.is_active, E_GAME_NOT_ACTIVE);
        assert!(game.total_numbers < 75, E_GAME_COMPLETE);
        
        let ts = timestamp::now_microseconds();
        let base_candidate: u64 = (ts % 75) + 1; // in [1, 75]
        
        let chosen = pick_next_available_number(&game.called_mask, base_candidate);
        
        let flag_ref = vector::borrow_mut(&mut game.called_mask, chosen);
        *flag_ref = true;
        
        vector::push_back(&mut game.numbers_called, chosen as u8);
        game.total_numbers = game.total_numbers + 1;
        
        if (game.total_numbers == 75) {
            game.is_active = false;
        };
    }
    
    fun pick_next_available_number(called_mask: &vector<bool>, start_from: u64): u64 {
        let offset: u64 = 0;
        while (offset < 75) {
            let candidate: u64 = ((start_from - 1 + offset) % 75) + 1; // in [1,75]
            let flag_ref = vector::borrow(called_mask, candidate);
            let is_called = *flag_ref;
            if (!is_called) {
                return candidate;
            };
            offset = offset + 1;
        };
        // Unreachable due to guards; return a valid placeholder
        1
    }
}
