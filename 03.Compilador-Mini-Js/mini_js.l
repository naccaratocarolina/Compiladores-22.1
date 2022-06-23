%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string>

	using namespace std;

  	// Declaracao das funcoes
  	void incrementa ();
  	int retorna (string, int);
%}

%option yylineno
%option noyywrap

/* Definições regulares */

DELIM [ \t\n]

WS	{DELIM}+

DIGITO [0-9]

LETRA [A-Za-z_]

ID {LETRA}({LETRA}|{DIGITO})*

INT {DIGITO}+

FLOAT {DIGITO}+(\.{DIGITO}+)?([Ee][+-]?{DIGITO}+)?

ASPAS_SIMPLES \'([^'\\\n]|(\'\')*|\\(.|\n))*\'

ASPAS_DUPLAS \"([^"\\\n]|(\"\")*|\\(.|\n))*\"

ASPAS_INVERTIDAS \`([^`\\]|(\`\`)*|\\(.|\n))*\`

STRING {ASPAS_SIMPLES}|{ASPAS_DUPLAS}|{ASPAS_INVERTIDAS}

%%

<<EOF>>	       {}

{WS}           { incrementa(); }

"var"		   { incrementa(); retorna("var", tk_var); }
"let"	       { incrementa(); retorna("let", tk_let); }
"const"		   { incrementa(); retorna("const", tk_const); }
"function"	   { incrementa(); retorna("function", tk_func); }
"for"		   { incrementa(); retorna("for", tk_for); }
"while"		   { incrementa(); retorna("while", tk_while); }
"if"		   { incrementa(); retorna("if", tk_if); }
"else"		   { incrementa(); retorna("else", tk_else); }
"return"	   { incrementa(); retorna("return", tk_return); }

"."		       { incrementa(); retorna(".", tk_pt); }
";"	       	   { incrementa(); retorna(";", tk_pt_vir); }
","	       	   { incrementa(); retorna(",", tk_vir); }
"("			   { incrementa(); retorna("(", tk_abre_paren); }
")"			   { incrementa(); retorna(")", tk_fecha_paren); }
"{"			   { incrementa(); retorna("{", tk_abre_chave); }
"}"			   { incrementa(); retorna("}", tk_fecha_chave); }
"["			   { incrementa(); retorna("[", tk_abre_colch); }
"]"			   { incrementa(); retorna("]", tk_fecha_colch); }

"+"            { incrementa(); retorna("+", tk_add); }
"-"            { incrementa(); retorna("-", tk_sub); }
"*"            { incrementa(); retorna("*", tk_mul); }
"/"            { incrementa(); retorna("/", tk_div); }
"%"            { incrementa(); retorna("%", tk_mod); }
"="            { incrementa(); retorna("=", tk_atribui); }
"=="	       { incrementa(); retorna("==", tk_ig); }
"!="	       { incrementa(); retorna("!=", tk_dif); }
"<"	           { incrementa(); retorna("<", tk_menor); }
">"	           { incrementa(); retorna(">", tk_maior); }
"<="           { incrementa(); retorna("<=", tk_menor_ig); }
">="           { incrementa(); retorna(">=", tk_maior_ig); }

"+="	       { incrementa(); retorna("+=", tk_add_atribui); }
"++"	       { incrementa(); retorna("++", tk_incrementa); }

{INT}          { incrementa(); retorna(yytext, tk_int); }
{FLOAT}        { incrementa(); retorna(yytext, tk_float); }
{STRING}       { incrementa(); retorna(yytext, tk_string); }
{ID}           { incrementa(); retorna(yytext, tk_id); }
.              { incrementa(); retorna(yytext, *yytext); }

%%

void incrementa () {
	for (int i=0; yytext[i]!='\0'; i++) {
		if (yytext[i] == '\n') {
			yylineno++; // Contador de linhas do Lex
		}
	}
}

int retorna (string valor, int token) {
	yylval.v.push_back(valor);
	return token;
}