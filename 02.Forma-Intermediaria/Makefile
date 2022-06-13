all: saida entrada.txt lex.yy.c
	./saida < entrada.txt

lex.yy.c: tradutor.l
	lex tradutor.l

saida: lex.yy.c entrada.txt
	g++ lex.yy.c -o saida
	
clean:
	rm saida lex.yy.c