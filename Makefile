include .env

compile: 
	@cocas \
	code/constants.asm \
	code/replacement.asm \
	code/enemy_ships.asm \
	code/write_tty.asm \
	code/player_ships.asm \
	code/main.asm \
	-o build/out.img
	@echo "Ok. File in build/out.img"

workspace-compile: 
	@cocas \
	code/constants.asm \
	code/enemy_ships.asm \
	code/replacement.asm \
	code/write_tty.asm \
	code/player_ships.asm \
	code/main.asm \
	-o ${OUT} 
	@echo "Ok. File in ${OUT}"

