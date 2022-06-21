%{
	#include <stdio.h>
	#include <stdlib.h>

  	// Declaracao das funcoes
  	void incrementa ();
%}

%option yylineno
%option noyywrap

/* Definições regulares */

DELIM [ \t\n]

WS	{DELIM}+

NL (\;(\r|\n|\r\n|;)*)

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

{WS}           { incrementa(); }
{NL}           { incrementa(); }

"var"		   { incrementa(); yylval.val = "&"; return tk_var; }
"let"	       { incrementa(); yylval.val = "&"; return tk_let; }
"const"		   { incrementa(); yylval.val = "&"; return tk_const; }
"function"	   { incrementa(); return tk_func; }
"for"		   { incrementa(); return tk_for; }
"while"		   { incrementa(); return tk_while; }
"if"		   { incrementa(); return tk_if; }
"else"		   { incrementa(); return tk_else; }
"return"	   { incrementa(); return tk_return; }

"."		       { incrementa(); return tk_pt; }
";"	       	   { incrementa(); return tk_pt_vir; }
","	       	   { incrementa(); return tk_vir; }
"("			   { incrementa(); return tk_abre_paren; }
")"			   { incrementa(); return tk_fecha_paren; }
"{"			   { incrementa(); return tk_abre_chave; }
"}"			   { incrementa(); return tk_fecha_chave; }
"["			   { incrementa(); return tk_abre_colch; }
"]"			   { incrementa(); return tk_fecha_colch; }

"+"            { incrementa(); return tk_add; }
"-"            { incrementa(); return tk_sub; }
"*"            { incrementa(); return tk_mul; }
"/"            { incrementa(); return tk_div; }
"%"            { incrementa(); return tk_mod; }
"="            { incrementa(); return tk_atribui; }
"=="	       { incrementa(); return tk_ig; }
"!="	       { incrementa(); return tk_dif; }

"+="	       { incrementa(); return tk_add_atribui; }
"++"	       { incrementa(); return tk_incrementa; }

{ID}           { incrementa(); yylval.val = yytext; return tk_id; }
{INT}          { incrementa(); yylval.val = yytext; return tk_int; }
{FLOAT}        { incrementa(); yylval.val = yytext; return tk_float; }
{STRING}       { incrementa(); yylval.val = yytext; return tk_string; }
.              { incrementa(); }

%%

void incrementa () {
	for (int i=0; yytext[i]!='\0'; i++) {
		if (yytext[i] == '\n') {
			yylineno++; // Contador de linhas do Lex
		}
	}
}