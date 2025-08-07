module anand_addr::BingoGame {
    use aptos_framework::timestamp;
    use std::vector;
    
    struct Game has store, key {
        numbers_called: vector<u8>,    
        total_numbers: u8,            
        entry_fee: u64,                
        prize_pool: u64,               
        is_active: bool,              
    }
    

    public fun create_game(owner: &signer, entry_fee: u64) {
        let game = Game {
            numbers_called: vector[],
            total_numbers: 0,
            entry_fee,
            prize_pool: 0,
            is_active: true,
        };
        move_to(owner, game);
    }
    
    public fun call_number(_caller: &signer, game_owner: address) acquires Game {
        let game = borrow_global_mut<Game>(game_owner);
        
        assert!(game.is_active, 1);
        assert!(game.total_numbers < 75, 2);
        

        let timestamp_val = timestamp::now_microseconds();
        let random_num = ((timestamp_val % 75) as u8) + 1;
        
        if (!vector::contains(&game.numbers_called, &random_num)) {
            vector::push_back(&mut game.numbers_called, random_num);
            game.total_numbers = game.total_numbers + 1;
        };
        
        if (game.total_numbers >= 75) {
            game.is_active = false;
        };
    }

}
