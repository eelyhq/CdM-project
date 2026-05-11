include .env

compile: 
	@mkdir -p ./build
	@cocas \
	./code/enemy_ships/enemy_ships_helpers.asm \
	./code/enemy_ships/enemy_ships.asm \
	\
	./code/player_ships.asm \
	\
	./code/game/utils.asm \
	./code/game/game_kill_end.asm \
	./code/game/game_bot_turn.asm \
	./code/game/game_player_turn.asm \
	./code/game/game.asm \
	\
	./code/constants.asm \
	./code/replacement.asm \
	./code/write_tty.asm \
	./code/main.asm \
	./code/draw.asm \
	-o ./build/out.img
	@echo "Ok. File in ./build/out.img"

workspace-compile: 
	@mkdir -p $(dir ${OUT})
	@cocas \
	./code/enemy_ships/enemy_ships_helpers.asm \
	./code/enemy_ships/enemy_ships.asm \
	\
	./code/player_ships.asm \
	\
	./code/game/utils.asm \
	./code/game/game_kill_end.asm \
	./code/game/game_bot_turn.asm \
	./code/game/game_player_turn.asm \
	./code/game/game.asm \
	\
	./code/constants.asm \
	./code/replacement.asm \
	./code/write_tty.asm \
	./code/main.asm \
	./code/draw.asm \
	-o ${OUT} 
	@echo "Ok. File in ${OUT}"
