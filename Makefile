include .env

compile: 
	@cocas \
	code/enemy_ships.asm \
	code/constants.asm \
	code/function.asm \
	code/replacement.asm \
	code/write_tty.asm \
	code/player_ships.asm \
	code/game.asm \
	code/main.asm \
	-o build/out.img
	@echo "Ok. File in build/out.img"

workspace-compile: 
	@cocas \
	code/enemy_ships.asm \
	code/constants.asm \
	code/function.asm \
	code/replacement.asm \
	code/write_tty.asm \
	code/player_ships.asm \
	code/game.asm \
	code/main.asm \
	-o ${OUT} 
	@echo "Ok. File in ${OUT}"

