%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string>

	using namespace std;

  	// Declaracao das funcoes
  	int retorna(string, int);
  	string trim (char*);
  	vector<string> split (string);
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
"var"       { return retorna("var", tk_var); }
"const"     { return retorna("const", tk_const); }
"for"       { return retorna("for", tk_for); }
"while"     { return retorna("while", tk_while); }
"if"        { return retorna("if", tk_if); }
"else"      { return retorna("else", tk_else); }
"function" 	{ return retorna("function", tk_func); }
"return" 	  { return retorna("return", tk_return); }
"true"	  	{ return retorna("true", tk_true); }
"false"	  	{ return retorna("false", tk_false); }
"asm{".*"}" { yylval.v = split(trim(yytext + 4)); return tk_asm; }

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

string trim( char *texto ) {
  string a = texto;
  return a.erase(a.size() - 1, a.size());
}

vector<string> split( string codigo ) {
  vector<std::string> tokens;
  size_t start = 0, end = 0;

  while ((end = codigo.find(" ", start)) != string::npos)
  {
      tokens.push_back(codigo.substr(start, end - start));
      start = end + 1;
  }

  tokens.push_back(codigo.substr(start));
  return tokens;
}