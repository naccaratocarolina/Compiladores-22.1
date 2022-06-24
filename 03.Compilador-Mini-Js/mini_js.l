%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string>

	using namespace std;

  	// Declaracao das funcoes
  	void incrementa (void);
%}

%option yylineno
%option noyywrap

/* Definições regulares */

DELIM [ \t\n]

WS {DELIM}+

DIGITO [0-9]

LETRA [A-Za-z_]

ID {LETRA}({LETRA}|{DIGITO})*

FLOAT {DIGITO}+(\.{DIGITO}+)?([Ee][+-]?{DIGITO}+)?

ASPAS_SIMPLES \'([^'\\\n]|(\'\')*|\\(.|\n))*\'

ASPAS_DUPLAS \"([^"\\\n]|(\"\")*|\\(.|\n))*\"

ASPAS_INVERTIDAS \`([^`\\]|(\`\`)*|\\(.|\n))*\`

STRING {ASPAS_SIMPLES}|{ASPAS_DUPLAS}|{ASPAS_INVERTIDAS}

%%

{WS}        { incrementa(); }

"let"       { incrementa(); yylval.v = vetor + "let"; return tk_let; }
"for"       { incrementa(); yylval.v = vetor + "for"; return tk_for; }
"while"     { incrementa(); yylval.v = vetor + "while"; return tk_while; }
"if"        { incrementa(); yylval.v = vetor + "if"; return tk_if; }
"else"      { incrementa(); yylval.v = vetor + "else"; return tk_else; }
"return"    { incrementa(); yylval.v = vetor + "return"; return tk_return; }

"=="        { incrementa(); yylval.v = vetor + "=="; return tk_ig; }
"!="        { incrementa(); yylval.v = vetor + "!="; return tk_dif; }
"<="        { incrementa(); yylval.v = vetor + "<="; return tk_menor_ig;  }
">="        { incrementa(); yylval.v = vetor + ">="; return tk_maior_ig; }
"+="        { incrementa(); yylval.v = vetor + "+="; return tk_add_atribui; }
"++"        { incrementa(); yylval.v = vetor + "++"; return tk_incrementa; }

{FLOAT}     { incrementa(); yylval.v = vetor + yytext; return tk_float; }
{STRING}    { incrementa(); yylval.v = vetor + yytext; return tk_string; }
{ID}        { incrementa(); yylval.v = vetor + yytext; return tk_id; }
.           { incrementa(); yylval.v = vetor + yytext; return *yytext; }

%%

void incrementa () {
	for (int i=0; yytext[i]!='\0'; i++) {
		if (yytext[i] == '\n') {
			yylineno++; // Contador de linhas do Lex
		}
	}
}