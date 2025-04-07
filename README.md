# active-directory

Este projeto visa melhorar a **segurança**, **governança** e **eficiência operacional** do ambiente de TI, para o ambiente de Active DIrectory

## :closed_lock_with_key: Benefícios da Sanitização Recorrente

- **Redução da superfície de ataque** (contas inativas = alto risco)
- **Facilidade em auditorias e compliance**
- **Ambiente AD mais limpo e gerenciável**
- **Visibilidade completa via Power BI**

## :gear: Funcionalidades

- Coleta de informações do AD com PowerShell
- Identificação de máquinas inativas via `LastLogonTimestamp`x PwdLastSet
- Exportação dos dados para CSV
- Dashboard Power BI com indicadores:
  - Total por sistema operacional
  - Histórico de inatividade
  - Histórico de sanitização
  - Detalhamento por Domínio
 

## :rocket: Como Usar

1. Clone o repositório:
   ```bash
   git clone https://github.com/caioasiqueira/active-directory.git

2. Execute o script PowerShell com privilégios administrativos:

.\scripts\LimpezaAD_WindowsServer.ps1

3. Importe o CSV gerado no Power BI usando o arquivo .pbix incluído na pasta powerbi.

4. Publique no Power BI Service (opcional) para acompanhar a evolução das contas inativas e agendar atualizações.

