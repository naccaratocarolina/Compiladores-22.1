%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <map>
#include <vector>

using namespace std;

struct Atributos {
  string val;
  vector<string> v;
};

#define YYSTYPE Atributos

// Declaracao das funcoes
int yylex (void);
int yyparse (void);
void yyerror (const char *);

vector<string> operator+ (vector<string>, vector<string>);
vector<string> operator+ (vector<string>, string);
vector<string> operator+ (string, vector<string>);

vector<string> concatena(vector<string>, vector<string>);
string gera_label (string);
vector<string> resolve_enderecos (vector<string>);
void imprime (vector<string>);

%}

%type <val> valores_literais obj_literal array_literal especificador_tipo

// Tokens
%token tk_var tk_let tk_const tk_func tk_for tk_while tk_if tk_else tk_return 
%token tk_id tk_int tk_float tk_string 

// Operadores
%token tk_pt tk_pt_vir tk_vir tk_abre_paren tk_fecha_paren tk_abre_chave tk_fecha_chave tk_abre_colch tk_fecha_colch
%token tk_add tk_sub tk_mul tk_div tk_mod tk_atribui tk_ig tk_dif tk_add_atribui tk_incrementa

// Start indica o símbolo inicial da gramática
%start S

%%

S
  : CMDS { imprime(resolve_enderecos($1.v)); }
  ;

CMDS
  : CMD { $$.v = $1.v; }
  | CMDs CMD { $$.v = $1.v + $2.v; }
  ;

CMD
  : EXPRESSAO_CMD { $$.v = $1.v + "^"; }
  | FOR_CMD
  | WHILE_CMD
  | IF_CMD
  | DECLARACAO_VAR
  ;

EXPRESSAO_CMD
  : EXPRESSAO { $$.v = $1.v; }
  | EXPRESSAO tk_pt_vir { $$.v = $1.v; }
  | tk_pt_vir { $$ = NULL; }
  ;

EXPRESSAO
  : EXPRESSAO_ATRIBUICAO
  | EXPRESSAO tk_vir EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $3.v; }
  ;

EXPRESSAO_ATRIBUICAO
  : EXPRESSAO_UNARIA OP_ATRIBUICAO EXPRESSAO_ATRIBUICAO
  ;

EXPRESSAO_UNARIA
  : EXPRESSAO_POSFIXA
  | EXPRESSAO_PRIMARIA tk_incrementa
  ;

OP_ATRIBUICAO
  : tk_atribui
  | tk_add_atribui
  ;

especificador_tipo
  : tk_var 
  | tk_let 
  | tk_const
  ;

%%

#include "lex.yy.c"

vector<string> operator+ ( vector<string> a, vector<string> b ) {
  return concatena( a, b );
}

vector<string> operator+ ( vector<string> a, string b ) {
  a.push_back( b );

  return a;
}

vector<string> operator+ ( string a, vector<string> b ) {
  return b+a;
}

vector<string> concatena( vector<string> a, vector<string> b ) {
  for(int i = 0; i < b.size(); i++ )
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

void imprime( vector<string> codigo ) {
    for (int i = 0; i < codigo.size(); i++) {
        cout << codigo[i] << " ";
    }
    cout << "." << endl;
}

void yyerror( const char* st ) {
   puts( st ); 
   printf( "Proximo a: %s\n", yytext );
   exit( 0 );
}

int main( int argc, char* argv[] ) {
  yyparse();
  
  return 0;
}