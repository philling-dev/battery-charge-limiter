## Fase 4: Testes de Unidade e Integração (Ambiente Simulado)

- **Objetivo:** Garantir a correção da lógica do script `bcl.py` e sua interação com o sistema de arquivos simulado.
- **Ferramentas:** `pytest` para o framework de testes e `unittest.mock` para simular operações de sistema de arquivos e saída padrão.
- **Cenários Testados:**
    - `find_control_file`:
        - Sucesso na detecção de um arquivo de controle (`charge_control_end_threshold`) em um diretório `BAT0` simulado.
        - Retorno `None` quando nenhum diretório `BAT*` ou arquivo de controle é encontrado.
    - `set_charge_limit`:
        - Sucesso na escrita de um valor válido (85%) no arquivo de controle simulado.
        - Tratamento correto de valores inválidos (ex: 101%), sem tentar escrever no arquivo.
        - Tratamento de erros de I/O (simulando "Permissão negada") ao tentar escrever no arquivo.
- **Resultados:** Todos os testes passaram com sucesso no ambiente simulado, confirmando a lógica interna do script.
- **Observação:** Estes testes validam a lógica do software. Testes em hardware real (em um laptop compatível) ainda são necessários para confirmar a interação com o sistema de arquivos `/sys` em diferentes modelos de bateria.