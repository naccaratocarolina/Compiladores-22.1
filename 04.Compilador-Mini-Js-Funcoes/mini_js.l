%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string>

	using namespace std;

  	// Declaracao das funcoes
  	int retorna(string, int);
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

NEG \-FLOAT

ASPAS_SIMPLES \'([^'\\\n]|(\'\')*|\\(.|\n))*\'

ASPAS_DUPLAS \"([^"\\\n]|(\"\")*|\\(.|\n))*\"

ASPAS_INVERTIDAS \`([^`\\]|(\`\`)*|\\(.|\n))*\`

STRING {ASPAS_SIMPLES}|{ASPAS_DUPLAS}|{ASPAS_INVERTIDAS}

%%

{WS}        {  }

"let"       { return retorna("let", tk_let); }
"for"       { return retorna("for", tk_for); }
"while"     { return retorna("while", tk_while); }
"if"        { return retorna("if", tk_if); }
"else"      { return retorna("else", tk_else); }
"function" 	{ return retorna("function", tk_func); }
"return" 	{ return retorna("return", tk_return); }

"=="        { return retorna("==", tk_ig); }
"!="        { return retorna("!=", tk_dif); }
"<="        { return retorna("<=", tk_menor_ig);  }
">="        { return retorna(">=", tk_maior_ig); }
"+="        { return retorna("+=", tk_add_atribui); }
"++"        { return retorna("++", tk_incrementa); }

{FLOAT}     { return retorna(yytext, tk_float); }
{STRING}    { return retorna(yytext, tk_string); }
{ID}        { return retorna(yytext, tk_id); }
.           { return retorna(yytext, *yytext); }

%%

int retorna (string valor, int tk) {  
  yylval.v = vetor + valor;
  return tk;
}