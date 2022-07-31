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
  string nome;
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
void declara (string, string);
void verifica_declaracao_duplicada (string, string);
void verifica_variavel_nao_declarada (string);
int quant_params = 0;
bool verifica_var_declaracao (string, string); // retorna true se precisar declarar, false c.c.

// Func
vector<string> funcoes;
vector<string> parametros_a_serem_declarados;
void desempilha_elementos_func (string, vector<string>);
bool dentro_escopo_func = false;
bool declarando_parametros = false;
bool dentro_return_func = false;
string funcao_escopo_atual;

// Array
vector<vector<string>> array_elementos;
vector<string> desempilha_elementos_array ();

%}

// Tokens
%token tk_let tk_var tk_const tk_for tk_while tk_if tk_else tk_float tk_string tk_id tk_func tk_return tk_true tk_false tk_asm

// Operadores
%token tk_ig tk_dif tk_menor_ig tk_maior_ig tk_add_atribui tk_incrementa

%left '<' '>' tk_menor_ig tk_maior_ig tk_ig tk_dif
%left '+' '-'
%left '*' '/' '%'
%right '=' tk_add_atribui tk_incrementa
%nonassoc ';' '(' '[' ']' ')' ':' ','

// Start indica o símbolo inicial da gramática
%start S

%%

S
  : { cria_escopo(); } CMDS { vector<string> v = resolve_enderecos($2.v + "." + funcoes); for (string c : v) { cout << c << " "; } cout << endl; encerra_escopo(); }
  ;

CMDS 
  : CMD
  | CMDS CMD { $$.v = $1.v + $2.v; }
  ;

CMD
  : EXPRESSAO_CMD FIM_CMD
  | FOR_CMD FIM_CMD
  | WHILE_CMD FIM_CMD
  | IF_CMD FIM_CMD
  | DECLARACAO_CMD FIM_CMD
  | FUNCAO_CMD FIM_CMD
  | JUMP_CMD FIM_CMD
  | ASM_CMD FIM_CMD
  | ESCOPO FIM_CMD
  ;

EXPRESSAO_CMD
  : EXPRESSAO { $$.v = $1.v + "^"; }
  ;

EXPRESSAO
  : EXPRESSAO_ATRIBUICAO
  ;

DECLARACAO_CMD
  : ESPECIFICADOR_TIPO LVALUE ATRIBUICAO_DECLARACAO { if (verifica_var_declaracao($1.v[0], $2.v[0])) { $2.v.push_back("&"); if ($3.v.size()) { $2.v.push_back($2.v[0]); } } $2.v.insert($2.v.end(), $3.v.begin(), $3.v.end()); if ($3.v.size()) { $2.v.push_back("="); $2.v.push_back("^"); } $$.v = $2.v; verifica_declaracao_duplicada($1.v[0], $2.v[0]); declara($1.v[0], $2.v[0]); } 
  | ESPECIFICADOR_TIPO LVALUE ',' LVALUE ATRIBUICAO_DECLARACAO { if (verifica_var_declaracao($1.v[0], $2.v[0])) { $2.v.push_back("&"); } $2.v.push_back($4.v[0]); if (verifica_var_declaracao($1.v[0], $2.v[0])) { $2.v.push_back("&"); if ($5.v.size()) { $2.v.push_back($2.v[$2.v.size()-2]); $2.v.insert($2.v.end(), $5.v.begin(), $5.v.end()); $2.v.push_back("="); $2.v.push_back("^"); } } $$.v = $2.v; verifica_declaracao_duplicada($1.v[0], $2.v[0]); declara($1.v[0], $2.v[0]); verifica_declaracao_duplicada($1.v[0], $4.v[0]); declara($1.v[0], $4.v[0]); }
  | ESPECIFICADOR_TIPO LVALUE ATRIBUICAO_DECLARACAO ',' LVALUE ATRIBUICAO_DECLARACAO { if (verifica_var_declaracao($1.v[0], $2.v[0])) { $2.v.push_back("&"); $2.v.push_back($2.v[0]); } $2.v.insert($2.v.end(), $3.v.begin(), $3.v.end()); $2.v.push_back("="); $2.v.push_back("^"); verifica_declaracao_duplicada($1.v[0], $2.v[0]); declara($1.v[0], $2.v[0]); $2.v.push_back($5.v[0]); if (verifica_var_declaracao($1.v[0], $5.v[0])) { $2.v.push_back("&"); $2.v.push_back($5.v[0]); } $2.v.insert($2.v.end(), $6.v.begin(), $6.v.end()); $2.v.push_back("="); $2.v.push_back("^"); $$.v = $2.v; verifica_declaracao_duplicada($1.v[0], $5.v[0]); declara($1.v[0], $5.v[0]); }
  ;

ATRIBUICAO_DECLARACAO
  : '=' EXPRESSAO { $$.v = $2.v; }
  | /* Vazio */ { $$.v = vetor; }
  ;

ESPECIFICADOR_TIPO
  : tk_let { $$.v = $1.v; }
  | tk_var { $$.v = $1.v; }
  | tk_const { $$.v = $1.v; }
  ;

FUNCAO_CMD 
  : tk_func LVALUE { funcao_escopo_atual = $2.v[0]; declarando_parametros = true; } '(' PARAMETROS ')' ESCOPO_FUNC { verifica_declaracao_duplicada("func", $2.v[0]); declara("func", $2.v[0]); string start_func = gera_label($2.v[0]); $$.v = $2.v + "&" + $2.v + "{}" + "=" + "'&funcao'" + start_func + "[=]" + "^"; desempilha_elementos_func(start_func, $7.v); declarando_parametros = false; }
  ;

PARAMETROS
  : LVALUE { if (declarando_parametros) { parametros_a_serem_declarados.push_back($1.v[0]); declara("param", $1.v[0]); } }
  | LVALUE ',' PARAMETROS { if (declarando_parametros) { parametros_a_serem_declarados.push_back($1.v[0]); declara("param", $1.v[0]); } }
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
  | '(' tk_id ')' { $$.v = $2.v; }
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
  : OBJETO_CHAVE ':' EXPRESSAO { $$.v = $1.v + $3.v + "[<=]"; }
  | OBJETO_CHAVE_VALOR ',' OBJETO_CHAVE ':' EXPRESSAO { $$.v = $1.v + $3.v + $5.v + "[<=]"; }
  | OBJETO_CHAVE_VALOR ',' { $$.v = $1.v + "[<=]"; }
  ;

OBJETO_CHAVE
  : LVALUE { $$.v = $1.v; }
  | tk_float { $$.v = $1.v; }
  | tk_string { $$.v = $1.v; }
  ;

ARRAY_LITERAL
  : '[' ']' { $$.v = vetor + "[]"; }
  | '[' ARRAY_ELEMENTOS ']' { vector<string> elem = desempilha_elementos_array(); $$.v = vetor + "[]" + elem; for (string v : elem) { cout << v << " "; } cout << endl; }
  ;

ARRAY_ELEMENTOS
  : EXPRESSAO { array_elementos.push_back($1.v); }
  | EXPRESSAO ',' ARRAY_ELEMENTOS { cout << $1.v[0] << endl; array_elementos.push_back($1.v); }
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
  : '{' { cria_escopo(); $1.v = vetor + "<{"; } CMDS '}' { $$.v = $1.v + $3.v + "}>"; encerra_escopo(); }
  ; 

ESCOPO_FUNC
  : '{' { cria_escopo(); dentro_escopo_func = true; } CMDS '}' { $$.v = vetor + $3.v; dentro_escopo_func = false; encerra_escopo(); }
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

bool verifica_var_declaracao (string tipo, string nome) {
  if (tipo != "var") return true;
  int cont = 0;
  for (int i=0; i<variaveis_declaradas.size(); i++) {
    if (variaveis_declaradas[i].tipo == "var" && 
        variaveis_declaradas[i].nome == nome) {
      cont++;
    }
    if (cont > 0) {
      return false;
    }
  }
  return true;
}

void declara (string tipo, string nome) {
  Variavel nova;
  nova.nome = nome;
  nova.tipo = tipo;
  nova.linha = yylineno;
  nova.escopo = ultimo_escopo;

  if (tipo == "func") {
    nova.quant_params = parametros_a_serem_declarados.size();
  }
  if (tipo == "param") {
    nova.escopo++;
  }

  variaveis_declaradas.push_back(nova);
}

void verifica_declaracao_duplicada (string tipo, string nome) {
  int cont = 0; // contador de ocorrencias
  for (int i=0; i<variaveis_declaradas.size(); i++) {
    if (variaveis_declaradas[i].nome == nome &&
        variaveis_declaradas[i].escopo >= ultimo_escopo) {
      cont++;
    }

    if (cont > 1 || dentro_escopo_func && cont == 1) {
          cout << "Erro: a variável '" << nome << "' já foi declarada na linha " << variaveis_declaradas[i].linha << "." << endl;
        exit(1);
      }
  }
}

void verifica_variavel_nao_declarada (string nome) {
  int cont = 0; // contador de ocorrencias
  for (int i=0; i<variaveis_declaradas.size(); i++) {
    if (variaveis_declaradas[i].nome == nome && 
      variaveis_declaradas[i].escopo <= ultimo_escopo) {
      cont++;
    }
  }
  
  if (cont == 0 && nome != funcao_escopo_atual && !dentro_escopo_func) {
    cout << "Erro: a variável '" << nome << "' não foi declarada." << endl;
        exit(1);
  }
}

vector<string> desempilha_elementos_array () {
  vector<string> v;
  int tam = array_elementos.size();
  for (int i=0; i<tam; i++) {
    v = v + to_string(i) + array_elementos.back() + "[<=]"; 
    array_elementos.pop_back();
  }
  return v;
}

void desempilha_elementos_func (string label, vector<string> bloco) {
  // Funcao nao possui parametros
  if (parametros_a_serem_declarados.size() == 0) {
    funcoes = funcoes + (":" + label) + bloco + "undefined" + "@" + "'&retorno'" + "@" + "~";
  }

  // Funcao possui parametros (um ou mais)
  else {
    vector<string> parametros;
    int i=0;
    for (string p : parametros_a_serem_declarados) {
      parametros = parametros + parametros_a_serem_declarados.back() + "&" + parametros_a_serem_declarados.back() + "arguments" + "@" + to_string(i) + "[@]" + "=" + "^";
      parametros_a_serem_declarados.pop_back();
      i++;
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