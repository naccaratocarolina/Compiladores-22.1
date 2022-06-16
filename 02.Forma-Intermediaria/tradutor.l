%{
  #include <stdio.h>
  #include <string>
  #include <map>
  #include <iostream>

  using namespace std;

  // Declaracao de variaveis
  int token;
  string lexema;
  int num_linhas = 1;
  int num_colunas = 1;

  enum { tk_int = 256, tk_num, tk_string, tk_id, tk_funcao, tk_print };

  map<int,string> nome_tokens = {
    { tk_int, "int" },
    { tk_num, "float" },
    { tk_string, "string" },
    { tk_id, "nome de identificador" },
    { tk_funcao, "funcao" },
    { tk_print, "comando print" }
  };

  // Declaracao das funcoes
  void A();
  void B();
  void C();
  void E();
  void E_linha();
  void H();
  void I();
  void T();
  void T_linha();
  void F();
  void casa (int);
  void print (string);
  void erro (string);
%}

/* Contador de linhas do lex */
%option noyywrap
%option yylineno

/* Definições regulares */
DELIM [ \t\n]

WS  {DELIM}+

NL (\r|\n|\r\n|;)

DIGITO [0-9]

LETRA [A-Za-z_]

ID {LETRA}({LETRA}|{DIGITO})*

NUM {DIGITO}+(\.{DIGITO}+)?([Ee][+-]?{DIGITO}+)?

ASPAS_SIMPLES \'([^'\\\n]|(\'\')*|\\(.|\n))*\'

ASPAS_DUPLAS \"([^"\\\n]|(\"\")*|\\(.|\n))*\"

STRING {ASPAS_SIMPLES}|{ASPAS_DUPLAS}

%%
    /* Padrões e ações para instalar o lexema - que possui comprimento igual a yyleng
       e primeiro caractere apontado por yytext - na tabela de simbolos. */

{WS}      { num_colunas += yyleng; }

{NL}      { num_linhas++;
            num_colunas = 1; }

{NUM}     { num_colunas += yyleng;
            return tk_num; }

"print"   { num_colunas += yyleng;
            return tk_print; }

{STRING}  { num_colunas += yyleng;
            return tk_string; }

{ID}      { num_colunas += yyleng;
            return tk_id; }

.         { num_colunas += yyleng;
            return *yytext; }

%%

int next_token () {
  int tmp = yylex();
  lexema = yytext;
  return tmp;
}

string nome_token (int token) {
  if(nome_tokens.find(token) != nome_tokens.end())
    return nome_tokens[token];
  else {
    string r;

    r = token;
    return r;
  }
}

void erro (string msg) {
  cout << "Linha " << num_linhas << " Coluna " << num_colunas << ": " << msg << endl;
  exit(1);
}

void print (string token) {
  cout << token << ' ';
}

void casa (int esperado) {
  if (esperado) {
    token = next_token();
  } else {
    erro("Caractere ilegal: " + lexema);
  }
}

void CMDs () {
  switch (token) {
    case tk_id:
      A();
      CMDs();
      break;
    case tk_print:
      B();
      CMDs();
      break;
  }
}

void A() {
// Guardamos o lexema pois a função 'casa' altera o seu valor.
  string temp = lexema;
  casa( tk_id );
  print( temp );
  casa( '=' );
  E();
  print( "=" );
}

void B () {
  casa(tk_print);
  E();
  print( "print #" );
}

void C () { // Fatorial
  if (token == '!') {
    casa( '!' );
    print( "fat #" );
    C();
  }
}

void D () { // XOR
  if (token == '^') {
    casa( '^' );
    F();
    C(); // Fatorial
    D(); // XOR
    print( "^" );
  }
}

void H () { // Operadores + e -
  if (token == '-') {
    print( "0" );
    casa( '-' );
    H(); // Operadores + e -
    print( "-" );
  }
  else if (token == '-') {
    casa( '+' );
    H(); // Operadores + e - 
  }
  else {
    F();
    D(); // XOR
  }
}

void G (string lexema) { // Id
  // Funcao ou expressao ou fatorial
  if (token == '(') {
    casa('(');
    E();
    // Parametros
    while (token == ',') {
      casa(',');
      E();
    }
    C(); // Fatorial
    D(); // XOR
    casa(')');
    print( lexema + " #" );
  }
  // Identificadores
  else {
    print( lexema + " @" );
  }
  D(); // XOR
  C(); // Fatorial
}

void E() {
  T();
  E_linha();
}

void E_linha() {
  switch( token ) {
    case '+' : 
      casa( '+' ); 
      T(); 
      print( "+"); 
      E_linha(); 
      break;
    case '-' : 
      casa( '-' ); 
      T(); 
      print( "-"); 
      E_linha(); 
      break;
  }
}

void T() {
  H(); // Operadores + e - 
  T_linha();
}

void T_linha() {
  switch( token ) {
    case '*' : 
      casa( '*' ); 
      H(); // Operadores + e - 
      print( "*" ); 
      T_linha(); 
      break;
    case '/' : 
      casa( '/' ); 
      H(); // Operadores + e - 
      print( "/" ); 
      T_linha(); 
      break;
  }
}

void F() {
  switch (token) {
    case tk_id: {
      string temp = lexema;
      casa( tk_id );
      G(temp); // Id
    }
      break;
    case tk_num: {
      string temp = lexema;
      casa( tk_num );
      print( temp );
      C(); // Fatorial
      D(); // XOR
    }
      break;
    case tk_string: {
      string temp = lexema;
      casa( tk_string ); print( temp );
    }
      break;
    case '(':
      casa( '(' ); 
      H(); // Operadores + e - 
      T_linha();
      E_linha();
      casa( ')' );
      C(); // Fatorial
      break;
    default:
      erro( "Caractere ilegal: " + lexema );
  }
}

int main() {
  token = next_token();

  CMDs();

  return 0;
}