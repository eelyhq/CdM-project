include .env

compile: 
	@cocas \
	code/enemy_ships/enemy_ships_helpers.asm \
	code/enemy_ships/enemy_ships.asm \
	\
	code/player_ships/player_ships_horizontal.asm \
	code/player_ships/player_ships_vertical_placement.asm \
	code/player_ships/player_ships_vertical_commit.asm \
	code/player_ships/player_ships.asm \
	\
	code/constants.asm \
	code/function.asm \
	code/replacement.asm \
	code/write_tty.asm \
	code/game.asm \
	code/main.asm \
	-o build/out.img
	@echo "Ok. File in build/out.img"

workspace-compile: 
	@cocas \
	code/enemy_ships/enemy_ships_helpers.asm \
	code/enemy_ships/enemy_ships.asm \
	\
	code/player_ships/player_ships_horizontal.asm \
	code/player_ships/player_ships_vertical_placement.asm \
	code/player_ships/player_ships_vertical_commit.asm \
	code/player_ships/player_ships.asm \
	\
	code/constants.asm \
	code/function.asm \
	code/replacement.asm \
	code/write_tty.asm \
	code/game.asm \
	code/main.asm \
	-o ${OUT} 
	@echo "Ok. File in ${OUT}"
