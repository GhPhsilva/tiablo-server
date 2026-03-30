# Adicionando Novos Itens ao Servidor

## Visão Geral

Adicionar um item envolve três camadas independentes que precisam estar sincronizadas pelo mesmo **item ID**:

| Camada | Ferramenta | Arquivo |
|---|---|---|
| Visual (sprite) | ObjectBuilder | `Tibia.spr` + `Tibia.dat` |
| Aparência (servidor) | Assets Editor | `data/items/appearances.dat` |
| Propriedades (servidor) | Editor de texto | `data/items/items.xml` |

---

## Pré-requisitos

- **ObjectBuilder** — edita `Tibia.spr` e `Tibia.dat` (formato antigo do client)
- **Assets Editor** — edita `appearances.dat` (formato protobuf do servidor)
- Sprite do item em PNG com **fundo transparente (alpha real)**

---

## Passo 1 — Preparar o Sprite

A imagem deve ter fundo **transparente real** (canal alpha), não fundo magenta/rosa.

Se a imagem tiver fundo magenta (255, 0, 255), converta antes de importar.

**Via PowerShell:**
```powershell
Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::new("C:\caminho\sprite.png")
$img.MakeTransparent([System.Drawing.Color]::FromArgb(255, 0, 255))
$img.Save("C:\caminho\sprite_fixed.png", [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()
```

**Via Paint.NET:**
1. Abra a imagem
2. `Magic Wand` → clica no fundo rosa → `Delete`
3. `File` → `Save As` → PNG (32-bit)

---

## Passo 2 — Adicionar Sprite ao Client (ObjectBuilder)

1. Abra o ObjectBuilder
2. Carregue o `Tibia.dat` e `Tibia.spr` da pasta `client/data/things/1100/`
3. Crie um novo item type (`Items` → `New`)
4. Importe o PNG corrigido como sprite
5. Configure dimensões e animações se necessário
6. **Anote o ID gerado** — será usado nos passos seguintes
7. Salve e substitua os arquivos em `client/data/things/1100/`

---

## Passo 3 — Adicionar Aparência ao Servidor (Assets Editor)

1. Abra o Assets Editor
2. Carregue o `data/items/appearances.dat`
3. Crie um novo item com o **mesmo ID** do Passo 2
4. Referencie o sprite ID correspondente
5. Salve o `appearances.dat`

---

## Passo 4 — Definir Propriedades no items.xml

Abra `data/items/items.xml` e adicione a entrada do item:

```xml
<item id="ITEM_ID" name="Nome do Item">
    <attribute key="weight" value="500" />
    <attribute key="attack" value="40" />
    <attribute key="defense" value="20" />
    <!-- outros atributos conforme necessário -->
</item>
```

Consulte `docs/items/type-attributes.md` e `docs/items/equippable-attributes.md` para a lista completa de atributos disponíveis.

---

## Checklist

- [ ] PNG com alpha transparente (sem fundo magenta)
- [ ] Sprite adicionado ao `Tibia.spr` via ObjectBuilder
- [ ] Item type criado no `Tibia.dat` via ObjectBuilder
- [ ] `Tibia.dat` e `Tibia.spr` copiados para `client/data/things/1100/`
- [ ] Item adicionado ao `appearances.dat` via Assets Editor (mesmo ID)
- [ ] Item adicionado ao `items.xml` com propriedades corretas (mesmo ID)
- [ ] IDs sincronizados entre as três camadas

---

## Problemas Comuns

**Item aparece com fundo rosa no client**
O sprite foi importado com fundo magenta sem converter para alpha. Corrija o PNG e reimporte no ObjectBuilder.

**Item não aparece no client**
Verifique se `Tibia.dat` e `Tibia.spr` foram copiados para a pasta correta do client após salvar no ObjectBuilder.

**Item aparece mas sem propriedades**
A entrada no `items.xml` está faltando ou com ID errado.

**IDs dessincronizados**
O ID no `Tibia.dat`, `appearances.dat` e `items.xml` devem ser o mesmo. Qualquer diferença causa comportamento incorreto.
