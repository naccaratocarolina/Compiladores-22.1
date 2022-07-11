%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <map>
#include <vector>
#include <queue>

using namespace std;

struct Atributos {
  vector<string> v;
};

#define YYSTYPE Atributos

// Funcoes default e tratamento de erro
extern int yylex (void);
int yyparse (void);
void yyerror (const char *);
void imprime_msg_erro (string, bool);

// Overload de operadores
vector<string> operator+ (vector<string>, vector<string>);
vector<string> operator+ (vector<string>, string);
vector<string> operator+ (string, vector<string>);
vector<string> concatena(vector<string>, vector<string>);

// Variaveis Globais
extern int yylineno;
vector<string> vetor;

// Label e endereco
string gera_label (string);
vector<string> resolve_enderecos (vector<string>);

// Variaveis, funcoes e parametros
typedef struct {
  string variavel;
  string tipo;
  int linha;
  int escopo;
  int quant_params = 0;
} Variavel;
vector<string> variaveis_a_serem_declaradas;
vector<Variavel> variaveis_declaradas;

queue<int> escopo;
int ultimo_escopo = 0; // quant de elementos em escopo

void cria_escopo (void);
void encerra_escopo (void);
void declara_variavel (string, string);
void verifica_declaracao_duplicada (string);
void verifica_variavel_nao_declarada (string);
int quant_params = 0;

// Func
vector<string> funcoes;
void declara_func (string);
void declara_param(string);
vector<string> parametros_a_serem_declarados;
void desempilha_elementos_func (string, vector<string>);
bool dentro_escopo_func = false;
bool dentro_return_func = false;

// Array
vector<vector<string>> array_elementos;
void desempilha_elementos_array (vector<string>);

%}

// Tokens
%token tk_let tk_var tk_const tk_for tk_while tk_if tk_else tk_float tk_string tk_id tk_func tk_return tk_true tk_false tk_asm

// Operadores
%token tk_ig tk_dif tk_menor_ig tk_maior_ig tk_add_atribui tk_incrementa

%left '<' '>' tk_menor_ig tk_maior_ig tk_ig tk_dif
%left '+' '-'
%left '*' '/' '%'
%right '=' tk_add_atribui tk_incrementa
%nonassoc ';' '(' '[' ']'

// Start indica o símbolo inicial da gramática
%start S

%%

S
  : { cria_escopo(); } CMDS { vector<string> v = resolve_enderecos($2.v + "." + funcoes); for (string c : v) { cout << c << " "; } cout << endl; encerra_escopo(); }
  ;

CMDS 
  : CMD FIM_CMD
  | CMDS CMD FIM_CMD { $$.v = $1.v + $2.v; }
  ;

CMD
  : EXPRESSAO_CMD
  | FOR_CMD
  | WHILE_CMD
  | IF_CMD
  | DECLARACAO_CMD 
  | FUNCAO_CMD
  | JUMP_CMD
  | ASM_CMD
  | ESCOPO
  ;

EXPRESSAO_CMD
  : EXPRESSAO { $$.v = $1.v + "^"; }
  ;

EXPRESSAO
  : EXPRESSAO_ATRIBUICAO
  ;

DECLARACAO_CMD
  : ESPECIFICADOR_TIPO DECLARACAO { $$.v = $2.v; for (string var : variaveis_a_serem_declaradas) { verifica_declaracao_duplicada(var); declara_variavel($1.v[0], var); variaveis_a_serem_declaradas.pop_back(); } }
  ;

DECLARACAO
  : DECLARACAO_VARIAVEL
  | DECLARACAO_VARIAVEL ',' DECLARACAO { $$.v = $1.v + $3.v; }
  ;

DECLARACAO_VARIAVEL
  : LVALUE { $$.v = $1.v + "&"; variaveis_a_serem_declaradas.push_back($1.v[0]); }
  | LVALUE '=' EXPRESSAO { $$.v = $1.v + "&" + $1.v + $3.v + "=" + "^"; variaveis_a_serem_declaradas.push_back($1.v[0]); }
  ;

ESPECIFICADOR_TIPO
  : tk_let { $$.v = $1.v; }
  | tk_var { $$.v = $1.v; }
  | tk_const { $$.v = $1.v; }
  ;

FUNCAO_CMD 
  : tk_func LVALUE { dentro_escopo_func = true; } '(' PARAMETROS ')' CMD { verifica_declaracao_duplicada($2.v[0]); declara_func($2.v[0]); string start_func = gera_label($2.v[0]); $$.v = $2.v + "&" + $2.v + "{}" + "=" + "'&funcao'" + start_func + "[=]" + "^"; desempilha_elementos_func(start_func, $7.v); dentro_escopo_func = false; }
  ;


PARAMETROS
  : LVALUE { if (dentro_escopo_func) { parametros_a_serem_declarados.push_back($1.v[0]); declara_param($1.v[0]); } }
  | LVALUE ',' PARAMETROS { if (dentro_escopo_func) { parametros_a_serem_declarados.push_back($1.v[0]); declara_variavel("param", $1.v[0]); } }
  |
  ;

JUMP_CMD
  : tk_return { dentro_return_func = true; } EXPRESSAO { dentro_return_func = false; $$.v = vetor + $3.v + "'&retorno'" + "@" + "~"; }
  ;

ASM_CMD
  : EXPRESSAO tk_asm { $$.v = $1.v + $2.v + "^"; }
  ;

FOR_CMD
  : tk_for '(' DECLARACAO_CMD ';' EXPRESSAO_ATRIBUICAO ';' EXPRESSAO_ATRIBUICAO ')' CMD { string start_for = gera_label("start_for"); string end_for = gera_label("end_for");  $$.v = $3.v + (":" + start_for) + $5.v + "!" + end_for + "?" + $9.v + $7.v + "^" + start_for + "#" + (":" + end_for); }
  | tk_for '(' EXPRESSAO_CMD ';' EXPRESSAO_ATRIBUICAO ';' EXPRESSAO_ATRIBUICAO ')' CMD { string start_for = gera_label("start_for"); string end_for = gera_label("end_for");  $$.v = $3.v + (":" + start_for) + $5.v + "!" + end_for + "?" + $9.v + $7.v + "^" + start_for + "#" + (":" + end_for); }
  ;

WHILE_CMD
  : tk_while '(' EXPRESSAO_ATRIBUICAO ')' CMD { string start_while = gera_label("start_while"); string end_while = gera_label("end_while"); $$.v = vetor + (":" + start_while) + $3.v + "!" + end_while + "?" + $5.v + start_while + "#" + (":" + end_while); }
  ;

IF_CMD
  : tk_if '(' EXPRESSAO_ATRIBUICAO ')' CMD tk_else CMD { string else_if = gera_label("else_if"); string continue_if = gera_label("continue_if"); $$.v = $3.v + "!" + else_if + "?" + $5.v + continue_if + "#" + (":" + else_if) + $7.v + (":" + continue_if); }
  | tk_if '(' EXPRESSAO_ATRIBUICAO ')' CMD { string end_if = gera_label("end_if"); $$.v = vetor + (":" + end_if) + $3.v + "!" + end_if + "?" + $5.v + end_if + "#" + (":" + end_if); }
  ;

EXPRESSAO_ATRIBUICAO
  : EXPRESSAO_IGUALDADE
  | LVALUE '=' EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $3.v + "="; verifica_variavel_nao_declarada($1.v[0]); }
  | LVALUEPROP '=' EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $3.v + "[=]"; verifica_variavel_nao_declarada($1.v[0]); }
  | LVALUE tk_add_atribui EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $1.v + "@" + $3.v + "+" + "="; verifica_variavel_nao_declarada($1.v[0]); verifica_variavel_nao_declarada($1.v[0]); }
  | LVALUEPROP tk_add_atribui EXPRESSAO_ATRIBUICAO { $$.v = $1.v + $1.v + "[@]" + $3.v + "+" + "[=]"; verifica_variavel_nao_declarada($1.v[0]); }
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
  | tk_true { $$.v = $1.v; }
  | tk_false { $$.v = $1.v; }
  | LVALUE { $$.v = $1.v + "@"; if (!dentro_return_func) { verifica_variavel_nao_declarada($1.v[0]); } }
  | LVALUEPROP { $$.v = $1.v + "[@]"; if (!dentro_return_func) { verifica_variavel_nao_declarada($1.v[0]); } }
  | '(' EXPRESSAO ')' { $$ = $2; }
  | OBJETO_LITERAL
  | ARRAY_LITERAL
  | FUNCAO_LITERAL
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
  | '(' LVALUE ')' PROP { $$.v = $2.v + "@" + $4.v; }
  ;

OBJETO_LITERAL
  : '{' '}' { $$.v = vetor + "{}"; }
  ;

ARRAY_LITERAL
  : '[' ']' { $$.v = vetor + "[]"; }
  | '[' ARRAY_ELEMENTOS ']' { $$.v = vetor + "[]"; desempilha_elementos_array($$.v); }
  ;

ARRAY_ELEMENTOS
  : EXPRESSAO { array_elementos.push_back($1.v); }
  | ARRAY_ELEMENTOS ',' EXPRESSAO_ATRIBUICAO { array_elementos.push_back($1.v); }
  ;

FUNCAO_LITERAL
  : LVALUE '(' FUNCAO_PARAMETROS ')' { $$.v = $3.v + to_string(quant_params) + $1.v + "@" + "$"; quant_params = 0; }
  | LVALUEPROP '(' FUNCAO_PARAMETROS ')' { $$.v = $3.v + to_string(quant_params) + $1.v + "[@]" + "$"; quant_params = 0; }
  ;

FUNCAO_PARAMETROS
  : EXPRESSAO { $$.v = $1.v; quant_params++; }
  | EXPRESSAO ',' FUNCAO_PARAMETROS { $$.v = $1.v + $3.v; quant_params++; }
  | { $$.v = vetor; }
  ;

ESCOPO
  : '{' { cria_escopo(); if (!dentro_escopo_func) { $1.v = vetor + "<{"; } else { $1.v = vetor; } } CMDS '}' { if (!dentro_escopo_func) { $$.v = $1.v + $3.v + "}>"; } else { $$.v = $1.v + $3.v; } encerra_escopo(); }
  ; 

FIM_CMD
  : TERMINADOR FIM_CMD
  | /* Vazio */
  ;

TERMINADOR
  : ';'
  ;

%%

#include "lex.yy.c"

void cria_escopo () {
  escopo.push(++ultimo_escopo); // insere no final
}

void encerra_escopo () {
  escopo.pop(); ultimo_escopo--; // remove do comeco
}

void declara_variavel (string tipo, string variavel) {
  Variavel var;
  var.variavel = variavel;
  var.tipo = tipo;
  var.linha = yylineno;
  var.escopo = ultimo_escopo;
  variaveis_declaradas.push_back(var);
}

void declara_func (string label) {
  Variavel func;
  func.variavel = label;
  func.tipo = "func";
  func.linha = yylineno;
  func.escopo = ultimo_escopo;
  func.quant_params = parametros_a_serem_declarados.size();
  variaveis_declaradas.push_back(func);
}

void declara_param(string parametro) {
  Variavel param;
  param.variavel = parametro;
  param.tipo = "param";
  param.linha = yylineno;
  param.escopo = ultimo_escopo + 1;
  variaveis_declaradas.push_back(param);
}

void verifica_declaracao_duplicada (string variavel) {
  for (int i=1; i<=ultimo_escopo; i++) {
  int cont = 0;
    for (int j=0; j<variaveis_declaradas.size(); j++) {
      if (variaveis_declaradas[j].variavel == variavel &&
          variaveis_declaradas[j].escopo == i &&
          variaveis_declaradas[j].escopo >= ultimo_escopo) {
        cont++;
        if (cont > 0) {
          cout << "Erro: a variável '" << variavel << "' já foi declarada na linha " << variaveis_declaradas[j].linha << "." << endl;
          exit(1);
        }
      }
    }
  }
}

void verifica_variavel_nao_declarada (string variavel) {
  for (int i=0; i<ultimo_escopo; i++) {
    int cont = 0;
    for (int j=0; j<variaveis_declaradas.size(); j++) {
      if (variaveis_declaradas[j].variavel == variavel &&
          variaveis_declaradas[j].escopo <= ultimo_escopo) {
        cont++;
        break;
      }
    }
    if (cont == 0) {
      cout << "Erro: a variável '" << variavel << "' não foi declarada." << endl;
      exit(1);
    }
  }
}

void desempilha_elementos_array (vector<string> v) {
  for (int i=0; i<=array_elementos.size(); i++) { 
    v = v + to_string(i) + array_elementos.back() + "[<=]"; 
    array_elementos.pop_back();
  }
}

void desempilha_elementos_func (string label, vector<string> bloco) {
  // Funcao nao possui parametros
  if (parametros_a_serem_declarados.size() == 0) {
    funcoes = funcoes + (":" + label) + bloco + "undefined" + "@" + "'&retorno'" + "@" + "~";
  }

  // Funcao possui parametros (um ou mais)
  else {
    vector<string> parametros;
    for (int i=0; i<=parametros_a_serem_declarados.size(); i++) {
      parametros = parametros + parametros_a_serem_declarados.back() + "&" + parametros_a_serem_declarados.back() + "arguments" + "@" + to_string(i) + "[@]" + "=" + "^";
      // Declara a variavel para ser possivel referenciar dentro do escopo da funcao sem necessidade de declarar
      parametros_a_serem_declarados.pop_back();
    }
    funcoes = funcoes + (":" + label) + parametros + bloco + "undefined" + "@" + "'&retorno'" + "@" + "~";
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