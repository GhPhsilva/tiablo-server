# Atributo `reflectpercentall`

Reflete uma porcentagem do dano recebido de volta ao atacante, para todos os tipos de dano.

## Conceito

```
dano_refletido = dano_recebido * reflectpercentall / 100
```

O percentual é acumulado de **todos os itens equipados**. Múltiplos itens com `reflectpercentall` somam seus valores antes de aplicar o bônus.

**Exemplo:** capacete com `reflectpercentall=3` + armadura com `reflectpercentall=5` = 8% de qualquer dano refletido.

---

## Sistema já implementado — nenhuma mudança de lógica necessária

O sistema de reflect **já existe e funciona completamente**. Não é necessário adicionar nenhuma lógica de combate.

### Parsing (`src/items/functions/item/item_parse.cpp:951`)

Já lê o atributo XML e preenche `abilities.reflectPercent[i]` para todos os tipos de dano:

```cpp
} else if (stringValue == "reflectpercentall") {
    int32_t value = pugi::cast<int32_t>(valueAttribute.value());
    std::transform(std::begin(abilities.reflectPercent), std::end(abilities.reflectPercent),
                   std::begin(abilities.reflectPercent), [&](const auto &i) { return i + value; });
}
```

### Acumulação por slot (`src/creatures/players/player.cpp:5529`)

`Player::getReflectPercent()` já itera `getEquippedItems()` e soma o valor de cada item equipado. Os slots cobertos incluem todos os tipos de item relevantes:

| Item | Slot | Coberto? |
|---|---|---|
| Helmet | `CONST_SLOT_HEAD` | ✅ |
| Armor | `CONST_SLOT_ARMOR` | ✅ |
| Leg | `CONST_SLOT_LEGS` | ✅ |
| Shield | `CONST_SLOT_RIGHT` | ✅ |
| Club / weapon | `CONST_SLOT_LEFT` | ✅ |

### Aplicação em combate (`src/game/game.cpp:6275`)

O dano refletido já é calculado e devolvido ao atacante automaticamente:

```cpp
double_t primaryReflectPercent = target->getReflectPercent(damage.primary.type, true);
int32_t reflectPercent = std::ceil(damage.primary.value * primaryReflectPercent / 100.);
int32_t reflectLimit   = std::ceil(attacker->getMaxHealth() * 0.01);
damageReflected.primary.value = std::max(-reflectLimit, reflectFlat + reflectPercent);
```

> **Cap de segurança:** o dano refletido é limitado a **1% do HP máximo do atacante** por hit, evitando abuso.

---

## O que falta: tooltip em `item.cpp`

`reflectPercent` não tem exibição na descrição do item. O jogador não vê o atributo. Apenas `reflectFlat` (dano físico fixo) aparece como "Damage Reflection".

### Modelo a seguir

O padrão de exibição de `absorbPercent` em `item.cpp` já resolve o caso "todos iguais" vs "valores individuais por tipo":

```cpp
// Verifica se todos os tipos têm o mesmo valor (caso "all")
int16_t show = itemType.abilities->absorbPercent[0];
if (show != 0) {
    for (size_t i = 1; i < COMBAT_COUNT; ++i) {
        if (itemType.abilities->absorbPercent[i] != show) { show = 0; break; }
    }
}

if (!show) {
    // Exibe por tipo: "protection fire +5%, ice +3%"
} else {
    itemDescription << fmt::format("protection all {:+}%", show);
}
```

### Plano de implementação

Adicionar um bloco análogo para `reflectPercent` nos locais em `item.cpp` onde os outros atributos defensivos são exibidos. O padrão é o mesmo — checar se todos os valores são iguais (caso `reflectpercentall`) e exibir "reflect all +X%" ou listar por tipo.

```cpp
// Após o bloco de reflectFlat, inserir:
int16_t showReflect = itemType.abilities->reflectPercent[0];
if (showReflect != 0) {
    for (size_t i = 1; i < COMBAT_COUNT; ++i) {
        if (itemType.abilities->reflectPercent[i] != showReflect) { showReflect = 0; break; }
    }
}

if (showReflect != 0) {
    // Todos os tipos iguais → "reflect all +X%"
    itemDescription << fmt::format("reflect all {:+}%", showReflect);
} else {
    // Tipos individuais → "reflect fire +X%, ice +Y%"
    for (size_t i = 0; i < COMBAT_COUNT; ++i) {
        if (itemType.abilities->reflectPercent[i] == 0) continue;
        itemDescription << fmt::format("reflect {} {:+}%",
            getCombatName(indexToCombatType(i)),
            itemType.abilities->reflectPercent[i]);
    }
}
```

O bloco deve ser inserido nos mesmos locais em que `reflectFlat` já aparece (`item.cpp` tem múltiplas funções de descrição).

---

## Uso no XML

Já funciona sem nenhuma mudança no parser:

```xml
<!-- Helmet -->
<item id="2392" article="a" name="helmet of the ancients">
    <attribute key="reflectpercentall" value="5"/>
</item>

<!-- Armor -->
<item id="2472" article="a" name="plate armor">
    <attribute key="reflectpercentall" value="3"/>
</item>

<!-- Leg -->
<item id="2650" article="a" name="plate legs">
    <attribute key="reflectpercentall" value="2"/>
</item>

<!-- Shield -->
<item id="2512" article="a" name="tower shield">
    <attribute key="reflectpercentall" value="4"/>
</item>

<!-- Club -->
<item id="2392" article="a" name="war hammer">
    <attribute key="reflectpercentall" value="6"/>
</item>
```

---

## Resumo de arquivos

| Arquivo | Natureza da mudança |
|---|---|
| `src/items/item.cpp` | +1 bloco de tooltip para `reflectPercent` (múltiplos locais) |
| `data/items/items.xml` | Atributos nos itens desejados |

Todos os outros arquivos (`items.hpp`, `item_parse.cpp`, `player.cpp`, `game.cpp`) **já estão prontos**.

---

## Notas

- `reflectpercentall` afeta **todos** os tipos de dano (físico, fogo, gelo, etc.) com o mesmo percentual.
- Se no futuro quiser reflect seletivo (ex: só físico), o parser já tem o case `reflectdamage` para dano fixo. Um case `reflectpercentphysical` pode ser adicionado analogamente.
- O cap de 1% HP do atacante é uma proteção do engine — múltiplos itens de reflect acumulam o percentual, mas o valor refletido por hit ainda é limitado.
- `reflectFlat` (dano fixo por hit) e `reflectPercent` são independentes e somam quando ambos estão presentes.
