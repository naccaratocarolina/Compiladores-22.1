all: saida
	echo "a b _1 ab1 _tab _5 _o" | ./a.out
	echo "1 221 0" | ./a.out
	echo "0.1 1.028 1.2E-4  0.2e+3 1e3" | ./a.out
	echo "for For fOr" | ./a.out
	echo "if IF" | ./a.out
	echo ">=" | ./a.out
	echo "for For fOr" | ./a.out
	echo "<=" | ./a.out
	echo "==" | ./a.out
	echo "!= " | ./a.out
	echo " /* Um comentario */ /* Outro comentario */ " | ./a.out
	echo " // comentario ate o final da linha " | ./a.out
	echo " // /*Esse comentario anula o inicio " | ./a.out
	echo " /* Esse comentario foi terminado! // */ " | ./a.out

lex.yy.c: scan.lex
	lex scan.lex

saida: lex.yy.c main.cc 
	g++ -Wall -std=c++17 main.cc -lfl
	
clean:
	rm saida lex.yy.c