all: saida entrada.txt lex.yy.c
	./saida < entrada.txt

lex.yy.c: mini_js.l
	lex mini_js.l

y.tab.c: mini_js.y
	yacc mini_js.y

saida: lex.yy.c y.tab.c
	g++ -o saida y.tab.c
	
clean:
	rm lex.yy.c;
	rm y.tab.c;
	rm saida;
	rm mini_js.tab.c;