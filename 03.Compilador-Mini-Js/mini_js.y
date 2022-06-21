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

vector<string> concatena(vector<string>, vector<string>);
string gera_label (string);
vector<string> resolve_enderecos (vector<string>);
void imprime (vector<string>);

%}

// Tokens
%token tk_pt tk_var tk_let tk_const tk_func tk_for tk_while tk_if tk_else tk_return tk_eq
%token tk_not_eq tk_add_assign tk_increase tk_id tk_int tk_float tk_string tk_semicolon tk_comma

// Start indica o símbolo inicial da gramática
%start S

%%

S
  : CMDS { imprime(resolve_enderecos($1.v)); }
  ;

CMDS
  : CMD
  | CMD CMDS { $$.v = $1.v + $2.v; }
  ;

CMD
  : EXPRESSAO_CMD
  | FOR_CMD
  | WHILE_CMD
  | IF_CMD
  ;

EXPRESSAO_CMD
  : EXPRESSAO
  | EXPRESSAO tk_semicolon { $$.v = $1.v; }
  | tk_semicolon { $$ = NULL; }
  ;

EXPRESSAO
  : EXPRESSAO_ATRIBUICAO
  | EXPRESSAO tk_comma EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $3.v; }
  ;

EXPRESSAO_ATRIBUICAO

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