# Compilando no Windows com x64 Native Tools Command Prompt

Este tutorial cobre a compilação do servidor Canary via linha de comando usando o **x64 Native Tools Command Prompt**, sem precisar abrir o Visual Studio.

---

## 1. Pré-requisitos

Instale os seguintes programas antes de começar:

- [Git](https://git-scm.com/download/win)
- [Visual Studio 2022 ou 2025](https://visualstudio.microsoft.com/vs/) com o workload **"Desktop development with C++"**
- [CMake 3.22+](https://cmake.org/download/) (marque a opção de adicionar ao PATH durante a instalação)
- [vcpkg](https://github.com/Microsoft/vcpkg)

---

## 2. Configurar o vcpkg

Abra o **PowerShell** e execute:

```powershell
git clone https://github.com/microsoft/vcpkg C:\vcpkg
cd C:\vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg integrate install
```

Defina a variável de ambiente `VCPKG_ROOT` (necessária para o CMake encontrar o vcpkg):

```powershell
[System.Environment]::SetEnvironmentVariable('VCPKG_ROOT', 'C:\vcpkg', [System.EnvironmentVariableTarget]::Machine)
```

> Feche e reabra o terminal após definir a variável para que ela entre em vigor.

---

## 3. Clonar o repositório

```powershell
cd C:\
git clone --recursive https://github.com/opentibiabr/canary.git
cd canary
```

---

## 4. Abrir o x64 Native Tools Command Prompt

No menu Iniciar, procure por:

```
x64 Native Tools Command Prompt for VS 20XX
```

> **Por que este terminal?** Ele configura automaticamente as variáveis de ambiente do compilador MSVC (`cl.exe`, `link.exe`, etc.) para a arquitetura x64. Usar o PowerShell ou CMD comum pode resultar em erros de compilador não encontrado.

Execute-o **como Administrador** se necessário.

Navegue até a pasta do servidor:

```cmd
cd C:\caminho\para\o\servidor
```

---

## 5. Gerar o cache do CMake

```cmd
cmake --preset windows-release
```

Este comando:
- Lê o `CMakePresets.json` da raiz do projeto
- Baixa e compila as dependências via vcpkg (pode demorar vários minutos na primeira vez)
- Gera os arquivos de build na pasta `windows-release/`

> Se aparecer o erro `VCPKG_ROOT` not set, feche e reabra o terminal após definir a variável no passo 2.

---

## 6. Compilar o servidor

```cmd
cmake --build --preset windows-release
```

- O binário gerado fica em `windows-release/` com o nome `canary.exe` (ou similar).
- Para compilar usando múltiplos núcleos e acelerar o processo, adicione `--parallel`:

```cmd
cmake --build --preset windows-release --parallel
```

---

## 7. Recompilar após mudanças

Após alterar arquivos C++, basta rodar novamente:

```cmd
cmake --build --preset windows-release
```

O CMake detecta automaticamente quais arquivos foram alterados e recompila apenas o necessário (compilação incremental).

---

## Solução de problemas comuns

| Erro | Causa provável | Solução |
|---|---|---|
| `'cl' is not recognized` | Terminal errado | Use o **x64 Native Tools Command Prompt** |
| `VCPKG_ROOT not set` | Variável de ambiente ausente | Defina `VCPKG_ROOT=C:\vcpkg` e reabra o terminal |
| `CMake version too low` | CMake desatualizado | Instale a versão 3.22+ e adicione ao PATH |
| Erros de linking em dependências | vcpkg corrompido ou incompleto | Execute `vcpkg install` na raiz do projeto manualmente |
| `error MSB...` no vcpkg | Overlay de porta inválido | Verifique se `VCPKG_OVERLAY_PORTS` aponta para a pasta correta |

---

## Referência rápida

```cmd
# Configurar (primeira vez ou após mudar CMakePresets.json)
cmake --preset windows-release

# Compilar
cmake --build --preset windows-release

# Compilar em paralelo (mais rápido)
cmake --build --preset windows-release --parallel

# Limpar e reconfigurar do zero
rmdir /s /q windows-release
cmake --preset windows-release
cmake --build --preset windows-release
```
