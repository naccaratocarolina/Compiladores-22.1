%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <map>
#include <vector>

using namespace std;

struct Atributos {
  vector<string> v;
};

#define YYSTYPE Atributos

// Declaracao das funcoes
extern int yylex (void);
int yyparse (void);
void yyerror (const char *);

vector<string> operator+ (vector<string>, vector<string>);
vector<string> operator+ (vector<string>, string);
vector<string> operator+ (string, vector<string>);
vector<string> concatena(vector<string>, vector<string>);

string gera_label (string);
vector<string> resolve_enderecos (vector<string>);

void registra_var_declarada (string);
void verifica_var_nao_declarada (string);
void verifica_var_declarada (string);
void imprime_msg_erro (string, bool);
void desempilha_elementos_array (vector<string>);

// Declaracao de variaveis auxiliares
extern int yylineno;
vector<string> vetor;
vector<vector<string>> array_elementos;
map<string, int> variaveis_declaradas; // map <nome da variavel, linha em que ela foi declarada>
vector<string> funcoes;
vector<string> parametros_func;

%}

// Tokens
%token tk_let tk_for tk_while tk_if tk_else tk_return tk_float tk_string tk_id tk_func tk_return

// Operadores
%token tk_ig tk_dif tk_menor_ig tk_maior_ig tk_add_atribui tk_incrementa

%left '<' '>' tk_menor_ig tk_maior_ig tk_ig tk_dif
%left '+' '-'
%left '*' '/' '%'
%right '=' tk_add_atribui tk_incrementa

// Start indica o símbolo inicial da gramática
%start S

%%

S
  : CMDS { vector<string> v = resolve_enderecos($1.v + "." + funcoes); for (string c : v) { cout << c << " "; } cout << "." << endl; }
  ;

CMDS 
  : CMD
  | CMDS CMD { $$.v = $1.v + $2.v; }
  ;

CMD
  : EXPRESSAO_CMD
  | FOR_CMD
  | WHILE_CMD
  | IF_CMD
  | DECLARACAO_CMD
  | JUMP_CMD
  ;

EXPRESSAO_CMD
  : EXPRESSAO ';' TERMINADOR { $$.v = $1.v + "^"; }
  ;

EXPRESSAO
  : EXPRESSAO_ATRIBUICAO
  ;

DECLARACAO_CMD
  : tk_let DECLARACAO ';' { $$.v = $2.v; }
  ;

DECLARACAO
  : DECLARACAO_VARIAVEL
  | DECLARACAO_VARIAVEL ',' DECLARACAO { $$.v = $1.v + $3.v; }
  ;

DECLARACAO_VARIAVEL
  : LVALUE { $$.v = $1.v + "&"; verifica_var_declarada($1.v[0]); registra_var_declarada($1.v[0]); }
  | LVALUE '=' EXPRESSAO { $$.v = $1.v + "&" + $1.v + $3.v + "=" + "^"; verifica_var_declarada($1.v[0]); registra_var_declarada($1.v[0]); }
  ;

FOR_CMD
  : tk_for '(' DECLARACAO_CMD EXPRESSAO_ATRIBUICAO ';' EXPRESSAO_ATRIBUICAO ')' ESCOPO { string start_for = gera_label("start_for"); string end_for = gera_label("end_for");  $$.v = $3.v + (":" + start_for) + $4.v + "!" + end_for + "?" + $8.v + $6.v + "^" + start_for + "#" + (":" + end_for); }
  | tk_for '(' EXPRESSAO_CMD EXPRESSAO_ATRIBUICAO ';' EXPRESSAO_ATRIBUICAO ')' ESCOPO { string start_for = gera_label("start_for"); string end_for = gera_label("end_for");  $$.v = $3.v + (":" + start_for) + $4.v + "!" + end_for + "?" + $8.v + $6.v + "^" + start_for + "#" + (":" + end_for); }
  ;
  ;

WHILE_CMD
  : tk_while '(' EXPRESSAO_ATRIBUICAO ')' ESCOPO { string start_while = gera_label("start_while"); string end_while = gera_label("end_while"); $$.v = vetor + (":" + start_while) + $3.v + "!" + end_while + "?" + $5.v + start_while + "#" + (":" + end_while); }
  ;

IF_CMD
  : tk_if '(' EXPRESSAO_ATRIBUICAO ')' ESCOPO tk_else ESCOPO { string else_if = gera_label("else_if"); string continue_if = gera_label("continue_if"); $$.v = $3.v + "!" + else_if + "?" + $5.v + continue_if + "#" + (":" + else_if) + $7.v + (":" + continue_if); }
  | tk_if '(' EXPRESSAO_ATRIBUICAO ')' ESCOPO { string end_if = gera_label("end_if"); $$.v = $3.v + "!" + end_if + "?" + $5.v + (":" + end_if); }
  ;

JUMP_CMD
  : tk_return { $$.v = vetor + "'&retorno'" + "@" + "~"; }
  | tk_return EXPRESSAO_CMD { $$.v = vetor + $2.v + "'&retorno'" + "@" + "~"; }
  ;

EXPRESSAO_ATRIBUICAO
  : EXPRESSAO_IGUALDADE
  | LVALUE '=' EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $3.v + "="; verifica_var_nao_declarada($1.v[0]); }
  | LVALUEPROP '=' EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $3.v + "[=]"; verifica_var_nao_declarada($1.v[0]); }
  | LVALUE tk_add_atribui EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $1.v + "@" + $3.v + "+" + "="; verifica_var_nao_declarada($1.v[0]); }
  | LVALUEPROP tk_add_atribui EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $1.v + "[@]" + $3.v + "+" + "[=]"; verifica_var_nao_declarada($1.v[0]); }
  ;

EXPRESSAO_IGUALDADE
  : EXPRESSAO_RELACIONAL
  | EXPRESSAO_IGUALDADE tk_ig EXPRESSAO_RELACIONAL { $$.v = $1.v + $3.v + "=="; }
  | EXPRESSAO_IGUALDADE tk_dif EXPRESSAO_RELACIONAL { $$.v = $1.v + $3.v + "!="; }
  ;

EXPRESSAO_RELACIONAL
  : EXPRESSAO_ADITIVA
  | EXPRESSAO_RELACIONAL '<' EXPRESSAO_ADITIVA { $$.v = $1.v + $3.v + "<"; }
  | EXPRESSAO_RELACIONAL '>' EXPRESSAO_ADITIVA { $$.v = $1.v + $3.v + ">"; }
  | EXPRESSAO_RELACIONAL tk_menor_ig EXPRESSAO_ADITIVA { $$.v = $1.v + $3.v + "<="; }
  | EXPRESSAO_RELACIONAL tk_maior_ig EXPRESSAO_ADITIVA { $$.v = $1.v + $3.v + ">="; }
  ;

EXPRESSAO_ADITIVA
  : EXPRESSAO_MULTIPLICATIVA
  | EXPRESSAO_ADITIVA '+' EXPRESSAO_MULTIPLICATIVA { $$.v = $1.v + $3.v + "+"; }
  | EXPRESSAO_ADITIVA '-' EXPRESSAO_MULTIPLICATIVA { $$.v = $1.v + $3.v + "-"; }
  ;

EXPRESSAO_MULTIPLICATIVA
  : EXPRESSAO_UNARIA
  | EXPRESSAO_MULTIPLICATIVA '*' EXPRESSAO_UNARIA { $$.v = $1.v + $3.v + "*"; }
  | EXPRESSAO_MULTIPLICATIVA '/' EXPRESSAO_UNARIA { $$.v = $1.v + $3.v + "/"; }
  | EXPRESSAO_MULTIPLICATIVA '%' EXPRESSAO_UNARIA { $$.v = $1.v + $3.v + "%"; }
  ;

EXPRESSAO_UNARIA
  : EXPRESSAO_POSFIXA
  | '-' tk_float { $$.v = vetor + "0" + $2.v + "-"; }
  ;

EXPRESSAO_POSFIXA
  : EXPRESSAO_PRIMARIA
  | LVALUE tk_incrementa { $$.v = $1.v + "@" + $1.v + $1.v + "@" + "1" + "+" + "=" + "^"; }
  ;

EXPRESSAO_PRIMARIA
  : tk_float { $$.v = $1.v; }
  | tk_string { $$.v = $1.v; }
  | LVALUE { $$.v = $1.v + "@"; verifica_var_nao_declarada($1.v[0]); }
  | LVALUEPROP { $$.v = $1.v + "[@]"; verifica_var_nao_declarada($1.v[0]); }
  | '(' EXPRESSAO ')' { $$ = $2; }
  | OBJETO_LITERAL
  | ARRAY_LITERAL
  | DECLARACAO_FUNCAO
  ;

DECLARACAO_FUNCAO
  : tk_func LVALUE '(' PARAMETROS ')' ESCOPO { string comeco_func = gera_label($2.v[0]); $$.v = $2.v + "&" + $2.v + "{}" + "=" + "'&funcao'" + comeco_func + "[=]" + "^"; funcoes = funcoes + (":" + comeco_func) + $6.v + "undefined" + "@" + "'&retorno'" + "@" + "~"; }
  ;

PARAMETROS
  : LVALUE
  | PARAMETROS ',' LVALUE { $$.v = $1.v + $2.v }
  | /* Vazio */
  ;

LVALUE
  : tk_id
  ;

PROP
  : '[' EXPRESSAO ']' { $$.v = $2.v; }
  | '.' tk_id { $$.v = $2.v; }
  | '[' EXPRESSAO ']' PROP { $$.v = $2.v + "[@]" + $4.v; }
  | '.' tk_id PROP { $$.v = $2.v + "[@]" + $3.v; }
  ;

LVALUEPROP
  : LVALUE PROP { $$.v = $1.v + "@" + $2.v; }
  ;

OBJETO_LITERAL
  : '{' '}' { $$.v = vetor + "{}"; }
  | '{' OBJETO_CHAVE_VALOR '}' { $$.v = vetor + "{}" + $2.v; }
  ;

OBJETO_CHAVE_VALOR
  : OBJETO_CHAVE ':' EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $3.v + "[<=]"; }
  | OBJETO_CHAVE_VALOR ':' OBJETO_CHAVE ',' EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $3.v + "[<=]" + $5.v; }
  | OBJETO_CHAVE_VALOR ':'{ $$.v = $1.v + "[<=]"; }
  ;

OBJETO_CHAVE
  : tk_string { $$.v = $1.v; }
  | tk_float { $$.v = $1.v; }
  | LVALUE { $$.v = $1.v; }
  ;

ARRAY_LITERAL
  : '[' ']' { $$.v = vetor + "[]"; }
  | '[' ARRAY_ELEMENTOS ']' { $$.v = vetor + "[]"; desempilha_elementos_array($$.v); }
  ;

ARRAY_ELEMENTOS
  : EXPRESSAO { array_elementos.push_back($1.v); }
  | ARRAY_ELEMENTOS ',' EXPRESSAO_ATRIBUICAO { array_elementos.push_back($1.v); }
  ;

ESCOPO
  : '{' CMDS '}' TERMINADOR { $$.v = $2.v; }
  | CMD { $$.v = $1.v; }
  ;

TERMINADOR
  : ';' 
  | /* Vazio */
  ;

%%

#include "lex.yy.c"

void registra_var_declarada (string variavel) {
  variaveis_declaradas[variavel] = yylineno;
}

void verifica_var_nao_declarada (string variavel) {
  if (variaveis_declaradas.count(variavel) == 0) imprime_msg_erro(variavel, true);
}

void verifica_var_declarada (string variavel) {
  if (variaveis_declaradas.count(variavel) > 0) imprime_msg_erro(variavel, false);
}

void imprime_msg_erro (string variavel, bool tipo) {
  if (tipo) {
    cout << "Erro: a variável '" << variavel << "' não foi declarada." << endl;
  } else {
    cout << "Erro: a variável '" << variavel << "' já foi declarada na linha " << variaveis_declaradas[variavel] << "." << endl;
  }
  exit(1);
}

void desempilha_elementos_array (vector<string> v) {
  for (int i=0; i<array_elementos.size(); i++) { 
    v = v + to_string(i) + array_elementos.back() + "[<=]"; 
    array_elementos.pop_back();
  }
}

vector<string> operator+( vector<string> a, vector<string> b ) {
  return concatena( a, b );
}

vector<string> operator+( vector<string> a, string b ) {
  a.push_back( b );
  return a;
}

vector<string> operator+( string a, vector<string> b ) {
  return b + a;
}

vector<string> concatena( vector<string> a, vector<string> b ) {
  for( int i = 0; i < b.size(); i++ )
    a.push_back( b[i] );
  return a;
}

string gera_label( string prefixo ) {
  static int n = 0;
  return prefixo + "_" + to_string( ++n ) + ":";
}

vector<string> resolve_enderecos( vector<string> entrada ) {
  map<string,int> label;
  vector<string> saida;
  for( int i = 0; i < entrada.size(); i++ ) 
    if( entrada[i][0] == ':' ) 
        label[entrada[i].substr(1)] = saida.size();
    else
      saida.push_back( entrada[i] );
  
  for( int i = 0; i < saida.size(); i++ ) 
    if( label.count( saida[i] ) > 0 )
        saida[i] = to_string(label[saida[i]]);
    
  return saida;
}

void yyerror( const char* st ) {
   puts( st ); 
   printf( "Proximo a: %s\n", yytext );
   exit( 1 );
}

int main( int argc, char* argv[] ) {
  yyparse();
  
  return 0;
}