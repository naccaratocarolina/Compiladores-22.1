%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string>

	using namespace std;

  	// Declaracao das funcoes
  	int retorna(string, int);
    string remove_ocorrencias (string);
    vector<string> tokeniza (string);
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

{WS}          {  }

"let"         { return retorna("let", tk_let); }
"var"         { return retorna("var", tk_var); }
"const"       { return retorna("const", tk_const); }
"for"         { return retorna("for", tk_for); }
"while"       { return retorna("while", tk_while); }
"if"          { return retorna("if", tk_if); }
"else"        { return retorna("else", tk_else); }
"function"    { return retorna("function", tk_func); }
"return"      { return retorna("return", tk_return); }
"true"        { return retorna("true", tk_true); }
"false"       { return retorna("false", tk_false); }
"asm{".*"}"   { yylval.v = tokeniza(yytext + 4); return tk_asm; }

"=="          { return retorna("==", tk_ig); }
"!="          { return retorna("!=", tk_dif); }
"<="          { return retorna("<=", tk_menor_ig);  }
">="          { return retorna(">=", tk_maior_ig); }
"+="          { return retorna("+=", tk_add_atribui); }
"++"          { return retorna("++", tk_incrementa); }

{FLOAT}       { return retorna(yytext, tk_float); }
{STRING}      { return retorna(yytext, tk_string); }
{ID}          { return retorna(yytext, tk_id); }
.             { return retorna(yytext, *yytext); }

%%

int retorna (string valor, int tk) {  
  yylval.v = vetor + valor;
  return tk;
}

string remove_ocorrencias (string lexema) {
  string res;
  res.reserve(lexema.size());
  for (size_t i=0; i<lexema.size(); ++i) {
    if (lexema[i] != '{' && lexema[i] != '}') {
      res += lexema[i];
    }
  }
  return res;
}

vector<string> tokeniza (string lexema) {
  vector<std::string> tokens;
  string codigo = remove_ocorrencias(lexema);
  size_t ini = 0, fim = 0;
  
  while ((fim = codigo.find(" ", ini)) != string::npos) {
      tokens.push_back(codigo.substr(ini, fim - ini));
      ini = fim + 1;
  }

  tokens.push_back(codigo.substr(ini));
  return tokens;
}