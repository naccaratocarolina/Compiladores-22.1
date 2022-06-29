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

// Declaracao de variaveis auxiliares
extern int yylineno;
vector<string> vetor;
map<string, int> variaveis_declaradas; // map <nome da variavel, linha em que ela foi>

%}

// Tokens
%token tk_let tk_for tk_while tk_if tk_else tk_return tk_float tk_string tk_id

// Operadores
%token tk_ig tk_dif tk_menor_ig tk_maior_ig tk_add_atribui tk_incrementa

%left '+' '-'
%left '*' '/' '%'
%left '<' '>' tk_menor_ig tk_maior_ig tk_ig tk_dif
%right '='

// Start indica o símbolo inicial da gramática
%start S

%%

S
  : CMDS { vector<string> v = resolve_enderecos($1.v); for (string c : v) { cout << c << " "; } cout << "." << endl; }
  ;

CMDS 
  : CMD
  | CMDS CMD { $$.v = $1.v + $2.v; }
  ;

CMD
  : ATRIBUICAO_CMD
  | FOR_CMD
  | WHILE_CMD
  | IF_CMD
  | DECLARACAO_CMD 
  ;

ATRIBUICAO_CMD
  : ATRIBUICAO TERMINADOR { $$.v = $1.v + "^"; }
  ;

ATRIBUICAO 
  : EXPRESSAO
  | LVALUE '=' ATRIBUICAO { $$.v = $1.v + $3.v + "="; verifica_var_nao_declarada($1.v[0]); }
  | LVALUEPROP '=' ATRIBUICAO { $$.v = $1.v + $3.v + "[=]"; verifica_var_nao_declarada($1.v[0]); }
  ;

FOR_CMD
  : tk_for '(' DECLARACAO_CMD ATRIBUICAO ';' ATRIBUICAO ')' ESCOPO TERMINADOR { string start_for = gera_label("start_for"); string end_for = gera_label("end_for");  $$.v = $3.v + (":" + start_for) + $4.v + "!" + end_for + "?" + $8.v + $6.v + "^" + start_for + "#" + (":" + end_for); }
  | tk_for '(' ATRIBUICAO ';' ATRIBUICAO ';' ATRIBUICAO ')' ESCOPO TERMINADOR { string start_for = gera_label("start_for"); string end_for = gera_label("end_for");  $$.v = $3.v + (":" + start_for) + $5.v + "!" + end_for + "?" + $9.v + $7.v + "^" + start_for + "#" + (":" + end_for); }
  ;

WHILE_CMD
  : tk_while '(' ATRIBUICAO ')' ESCOPO TERMINADOR { string start_while = gera_label("start_while"); string end_while = gera_label("end_while"); $$.v = vetor + (":" + start_while) + $3.v + "!" + end_while + "?" + $5.v + start_while + "#" + (":" + end_while); }
  ;

IF_CMD
  : tk_if '(' EXPRESSAO ')' ESCOPO tk_else ESCOPO { string else_if = gera_label("else_if"); string continue_if = gera_label("continue_if"); $$.v = $3.v + "!" + else_if + "?" + $5.v + continue_if + "#" + (":" + else_if) + $7.v + (":" + continue_if); }
  | tk_if '(' EXPRESSAO ')' ESCOPO { string end_if = gera_label("end_if"); $$.v = $3.v + "!" + end_if + "?" + $5.v + (":" + end_if); }
  ;

DECLARACAO_CMD
  : tk_let DECLARACAO_VARIAVEL TERMINADOR { $$.v = $2.v; }
  ;

DECLARACAO_VARIAVEL
  : DECLARACAO
  | DECLARACAO ',' DECLARACAO_VARIAVEL { $$.v = $1.v + $3.v; }
  ;

DECLARACAO
  : LVALUE { $$.v = $1.v + "&"; verifica_var_declarada($1.v[0]); registra_var_declarada($1.v[0]); }
  | LVALUE '=' EXPRESSAO { $$.v = $1.v + "&" + $1.v + $3.v + "=" + "^"; verifica_var_declarada($1.v[0]); registra_var_declarada($1.v[0]); }
  ;

EXPRESSAO
  : EXPRESSAO_PRIMARIA 
  | EXPRESSAO '+' EXPRESSAO { $$.v = $1.v + $3.v + "+"; }
  | EXPRESSAO '-' EXPRESSAO { $$.v = $1.v + $3.v + "-"; }
  | EXPRESSAO '*' EXPRESSAO { $$.v = $1.v + $3.v + "*"; }
  | EXPRESSAO '/' EXPRESSAO { $$.v = $1.v + $3.v + "/"; }
  | EXPRESSAO '%' EXPRESSAO { $$.v = $1.v + $3.v + "%"; }
  | EXPRESSAO '<' EXPRESSAO { $$.v = $1.v + $3.v + "<"; }
  | EXPRESSAO '>' EXPRESSAO { $$.v = $1.v + $3.v + ">"; }
  | EXPRESSAO tk_menor_ig EXPRESSAO { $$.v = $1.v + $3.v + "<="; }
  | EXPRESSAO tk_maior_ig EXPRESSAO { $$.v = $1.v + $3.v + ">="; }
  | EXPRESSAO tk_ig EXPRESSAO { $$.v = $1.v + $3.v + "=="; }
  | EXPRESSAO tk_dif EXPRESSAO { $$.v = $1.v + $3.v + "!="; }
  ;

EXPRESSAO_PRIMARIA
  : tk_float 
  | '-' tk_float { $$.v = "0" + $2.v + "-"; }
  | tk_string
  | LVALUE { $$.v = $1.v + "@"; verifica_var_nao_declarada($1.v[0]); }
  | LVALUE tk_incrementa { }
  | LVALUEPROP { $$.v = $1.v + "[@]"; verifica_var_nao_declarada($1.v[0]); }
  | '(' EXPRESSAO ')' { $$ = $2; }
  | OBJETO_LITERAL { $$.v = vetor + "{}"; }
  | ARRAY_LITERAL { $$.v = vetor + "[]"; }
  ;

LVALUE
  : tk_id
  ;

PROP
  : '[' ATRIBUICAO ']' { $$.v = $2.v; }
  | '.' tk_id { $$.v = $2.v; }
  | '[' ATRIBUICAO ']' PROP { $$.v = $2.v + "[@]" + $4.v; }
  | '.' tk_id PROP { $$.v = $2.v + "[@]" + $3.v; }
  ;

LVALUEPROP
  : LVALUE PROP { $$.v = $1.v + "@" + $2.v; }
  ;

OBJETO_LITERAL
  : '{' '}' 
  ;

ARRAY_LITERAL
  : '[' ']'
  ;

ESCOPO
  : '{' '}' { $$.v = vetor + ""; }
  | '{' CMDS '}' { $$.v = $2.v; }
  | CMD
  ;

TERMINADOR
  : ';' 
  ;

%%

#include "lex.yy.c"

void registra_var_declarada (string variavel) {
  variaveis_declaradas[variavel] = yylineno;
}

void verifica_var_nao_declarada (string variavel) {
  if (variaveis_declaradas.count(variavel) == 0) {
    cout << "Erro: a variável '" << variavel << "' não foi declarada." << endl;
    exit(1);
  }
}

void verifica_var_declarada (string variavel) {
  if (variaveis_declaradas.count(variavel) > 0) {
    cout << "Erro: a variável '" << variavel << "' já foi declarada na linha " << variaveis_declaradas[variavel] << "." << endl;
    exit(1);
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