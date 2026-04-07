compile: 
	@cocas constants.asm main.asm -o build/out.img
	@echo "Ok. File in build/out.img"

workspace-compile: 
	@cocas constants.asm main.asm -o ../workspace/build/out.img
	@echo "Ok. File in ../workspace/build/out.img"

