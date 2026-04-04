# Suporte a Múltiplos Arquivos XML de Items

## Problema

O servidor carrega os items a partir de um único arquivo fixo:

```
data/items/items.xml
```

O código em `src/items/items.cpp:200` não possui suporte nativo a `<include>` ou referência a outros arquivos XML. Isso significa que não é possível criar um `epic_items.xml` separado e referenciá-lo dentro do `items.xml`.

---

## Solução Proposta

Modificar o método `Items::loadFromXml()` em `src/items/items.cpp` para, após carregar o `items.xml` principal, varrer uma pasta de extensões e carregar automaticamente qualquer arquivo `.xml` encontrado.

### Pasta de extensões

```
data/items/extensions/
```

Qualquer arquivo `.xml` colocado nessa pasta seguiria o mesmo formato do `items.xml`:

```xml
<!-- data/items/extensions/epic_items.xml -->
<items>
    <item id="30001" name="Epic Sword">
        <attribute key="attack" value="60"/>
        <attribute key="slottype" value="two-handed"/>
    </item>
</items>
```

### Alteração necessária no C++

Arquivo: `src/items/items.cpp`  
Método: `Items::loadFromXml()`

Após o loop principal que processa o `items.xml`, adicionar um segundo loop que:

1. Verifica se a pasta `data/items/extensions/` existe
2. Itera sobre todos os arquivos `.xml` da pasta
3. Para cada arquivo, carrega o documento XML e executa o mesmo `parseItemNode()` usado pelo arquivo principal

```cpp
// Pseudocódigo da lógica a adicionar
auto extensionsFolder = g_configManager().getString(CORE_DIRECTORY) + "/items/extensions/";

if (std::filesystem::exists(extensionsFolder)) {
    for (auto &entry : std::filesystem::directory_iterator(extensionsFolder)) {
        if (entry.path().extension() != ".xml") {
            continue;
        }

        pugi::xml_document extDoc;
        pugi::xml_parse_result extResult = extDoc.load_file(entry.path().string().c_str());
        if (!extResult) {
            printXMLError(__FUNCTION__, entry.path().string(), extResult);
            continue;
        }

        for (auto itemNode : extDoc.child("items").children()) {
            if (auto idAttribute = itemNode.attribute("id")) {
                parseItemNode(itemNode, pugi::cast<uint16_t>(idAttribute.value()));
                continue;
            }
            // tratar fromid/toid igual ao loop principal
        }
    }
}
```

### Includes necessários

```cpp
#include <filesystem>
```

---

## Vantagens

- `items.xml` permanece limpo com apenas os items base do servidor
- Novos sistemas (epic items, custom items, etc.) ficam em arquivos separados
- Basta adicionar um `.xml` na pasta `extensions/` — sem tocar no core
- Fácil de manter e versionar separadamente

## Desvantagens

- Requer compilação do servidor para ativar o suporte
- A ordem de carregamento dos arquivos de extensão segue a ordem do filesystem (não garantida em todos os SOs) — IDs duplicados entre arquivos de extensão gerarão warning de `Duplicate item`

---

## Observações

- IDs dos items de extensão **não podem conflitar** com IDs existentes no `items.xml` principal
- O formato do XML de extensão deve ser idêntico ao do `items.xml` (nó raiz `<items>`, filhos `<item>`)
- A pasta `extensions/` não precisa existir para o servidor iniciar — o código deve verificar a existência antes de iterar
