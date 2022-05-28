/* Definições regulares */

DELIM [ \t\n]

WS	{DELIM}+

DIGITO [0-9]

LETRA [A-Za-z]

ID [\$_{LETRA}]*?({LETRA}|{DIGITO})*

INT {DIGITO}+

FLOAT {DIGITO}+(\.{DIGITO}+)?([Ee][+-]?{DIGITO}+)?

FOR [Ff][Oo][Rr]

IF [Ii][Ff]

UMA_LINHA \/\/[^\n]*

MULTI_LINHA \*\/.*|\/\*([^*]|\*+[^*/])*\*\/

COMENTARIO {UMA_LINHA}|{MULTI_LINHA}

ASPAS_SIMPLES \'([^'\\\n]|(\'\')*|\\(.|\n))*\'

ASPAS_DUPLAS \"([^"\\\n]|(\"\")*|\\(.|\n))*\"

ASPAS_INVERTIDAS \`([^`\\]|(\`\`)*|\\(.|\n))*\`

STRING {ASPAS_SIMPLES}|{ASPAS_DUPLAS}

STRING2 {ASPAS_INVERTIDAS}

%%
    /* Padrões e ações para instalar o lexema - que possui comprimento igual a yyleng 
       e primeiro caractere apontado por yytext - na tabela de simbolos. */

{WS}         { }

{IF}         { return _IF; }

{FOR}        { return _FOR; }

{INT}        { return _INT; }

{FLOAT}      { return _FLOAT; }

">="         { return _MAIG; }

"<="         { return _MEIG; }

"=="         { return _IG; }

"!="         { return _DIF; }

{STRING}     { return _STRING; }

{STRING2}    { return _STRING2; }

{COMENTARIO} { return _COMENTARIO; }

{ID}         { return _ID; }

.            { return *yytext; }

%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */