GAME=breackout

ADDRWINDOWS=/mnt/c/Users/theoc/Coding/Perso/GameBoyExperimentation

COLORPALETTE=#071821, #306850, #86c06c, #e0f8cf

all: $(GAME) clean windows

$(GAME): $(GAME).gb
	rgbfix -v -p 0xFF $(GAME).gb -t breackout

$(GAME).gb: main.o
	rgblink -o $(GAME).gb main.o 

main.o: main.asm
	rgbasm -o main.o main.asm 

windows:
	cp $(GAME).gb $(ADDRWINDOWS)
clean: 
	rm -rf *.o

mrproprer:
	rm -rf $(GAME)


images: 
	rgbgfx -c '#071821, #306850, #86c06c, #e0f8cf' -A -o res/img/heart_empty.2bpp res/img/heart_empty.png 
