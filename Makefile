compile: 
	@cocas \
	code/constants.asm \
	code/replacement.asm \
	code/write_tty.asm \
	code/main.asm \
	-o build/out.img
	@echo "Ok. File in build/out.img"

workspace-compile: 
	@cocas \
	code/constants.asm \
	code/replacement.asm \
	code/write_tty.asm \
	code/main.asm \
	-o ../workspace/build/out.img
	@echo "Ok. File in ../workspace/build/out.img"

