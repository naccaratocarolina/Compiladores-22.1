#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <map>
#include <vector>
#include <queue>

using namespace std;

typedef struct {
	string variavel;
	string tipo;
	int linha;
	int escopo;
} Variavel;
vector<Variavel> variaveis_declaradas;

queue<int> escopo;
int ultimo_escopo = 0; // quant de elementos em escopo

void cria_escopo () {
	cout << "Escopo criado!" << endl;
	escopo.push(++ultimo_escopo); // insere no final
	cout << "Ultimo escopo: " << ultimo_escopo << endl;
}

void encerra_escopo () {
	cout << "Escopo removido!" << endl;
	escopo.pop(); ultimo_escopo--; // remove do comeco
}

void declara_variavel (string variavel, string tipo, int linha) {
	Variavel v;
	v.variavel = variavel;
	v.tipo = tipo;
	v.linha = linha;
	v.escopo = ultimo_escopo;
	variaveis_declaradas.push_back(v);
	cout << "Variavel '" << variavel << "' declarada no escopo " << ultimo_escopo << endl;
}

void verifica_declaracao_duplicada (string variavel) {
	// Para cada escopo, mantem um contador
	// da quantidade de vezes que a variavel
	// dada como parametro foi declarada
	for (int i=0; i<ultimo_escopo; i++) {
	int cont = 0;
		// Itera pelo vetor de variaveis declaradas e conta a 
		// quantidade de vezes que a variavel dada como parametro
		// foi declarada
		for (int j=0; j<variaveis_declaradas.size(); j++) {
			if (variaveis_declaradas[j].variavel == variavel &&
				variaveis_declaradas[j].escopo == i) {
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
				variaveis_declaradas[j].escopo == i) {
				cont++;
			}
		}
		if (cont == 0) {
			cout << "Erro: a variável '" << variavel << "' não foi declarada." << endl;
			exit(1);
		}
	}
}

int main() {
	cria_escopo();
	declara_variavel("a", "let", 1);
	remove_escopo();
	cria_escopo();
	verifica_variavel_nao_declarada ("a");
	return 0;
}