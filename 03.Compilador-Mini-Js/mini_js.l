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

"."		       { incrementa(); return tk_pt; }

"var"		   { incrementa(); yylval.val = "&"; return tk_var; }

"let"	       { incrementa(); yylval.val = "&"; return tk_let; }

"const"		   { incrementa(); yylval.val = "&"; return tk_const; }

"function"	   { incrementa(); return tk_func; }

"for"		   { incrementa(); return tk_for; }

"while"		   { incrementa(); return tk_while; }

"if"		   { incrementa(); return tk_if; }

"else"		   { incrementa(); return tk_else; }

"return"	   { incrementa(); return tk_return; }

"=="	       { incrementa(); return tk_eq; }

"!="	       { incrementa(); return tk_not_eq; }

"+="	       { incrementa(); return tk_add_assign; }

"++"	       { incrementa(); return tk_increase; }

";"	       	   { incrementa(); return tk_semicolon; }

","	       	   { incrementa(); return tk_comma; }

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