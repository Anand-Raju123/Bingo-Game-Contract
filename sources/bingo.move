module anand_addr::BingoGame {
    use aptos_framework::timestamp;
    use std::vector;
    
    /// Struct representing a bingo game
    struct Game has store, key {
        numbers_called: vector<u8>,    // Numbers that have been called (1-75)
        total_numbers: u8,             // Total numbers called so far
        entry_fee: u64,                // Cost to join the game
        prize_pool: u64,               // Total prize money collected
        is_active: bool,               // Whether the game is currently active
    }
    
    /// Function to create a new bingo game
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
    
    /// Function to generate and call the next bingo number
    public fun call_number(_caller: &signer, game_owner: address) acquires Game {
        let game = borrow_global_mut<Game>(game_owner);
        
        // Check if game is active and not all numbers called
        assert!(game.is_active, 1);
        assert!(game.total_numbers < 75, 2);
        
        // Simple pseudo-random number generation using timestamp
        let timestamp_val = timestamp::now_microseconds();
        let random_num = ((timestamp_val % 75) as u8) + 1;
        
        // Ensure number hasn't been called before
        if (!vector::contains(&game.numbers_called, &random_num)) {
            vector::push_back(&mut game.numbers_called, random_num);
            game.total_numbers = game.total_numbers + 1;
        };
        
        // End game if all numbers called
        if (game.total_numbers >= 75) {
            game.is_active = false;
        };
    }
}