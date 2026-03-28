# Atributos com "Type" — items.xml

Arquivo fonte: `data/items/items.xml`
Critério: atributos `<attribute>` cujo `key` contém a palavra **Type** (case-sensitive, capital T).

---

## Keys encontradas

| key | Descrição |
|---|---|
| `weaponType` | Tipo da arma |
| `shootType` | Projétil disparado |
| `slotType` | Slot especial de equipamento |
| `wandType` | Elemento do wand/rod |
| `eventType` | Evento de tile/objeto |

> **Nota:** `primarytype` existe no XML mas usa casing todo minúsculo, portanto não é capturado por uma busca case-sensitive em "Type". Seus valores estão documentados em [equippable-attributes.md](equippable-attributes.md).

---

## weaponType

Classifica o tipo de arma equipável.

| Valor | Descrição |
|---|---|
| `sword` | Espada |
| `axe` | Machado |
| `club` | Clava |
| `distance` | Arma de distância (bow/crossbow) |
| `wand` | Wand |
| `shield` | Escudo |
| `spellbook` | Livro de feitiços |
| `ammunition` | Munição (tipo primário) |
| `ammo` | Munição (tipo secundário/interno) |
| `missile` | Arremessável (spear, throwingstar, etc.) |

---

## shootType

Define o projétil visual e de dano disparado pela arma.

| Valor |
|---|
| `arrow` |
| `bolt` |
| `burstarrow` |
| `crystallinearrow` |
| `death` |
| `diamondarrow` |
| `drillbolt` |
| `earth` |
| `eartharrow` |
| `enchantedspear` |
| `energy` |
| `envenomedarrow` |
| `fire` |
| `flammingarrow` |
| `flasharrow` |
| `gloothspear` |
| `greenstar` |
| `holy` |
| `huntingspear` |
| `ice` |
| `infernalbolt` |
| `leafstar` |
| `onyxarrow` |
| `piercingbolt` |
| `poisonarrow` |
| `powerbolt` |
| `prismaticbolt` |
| `redstar` |
| `royalspear` |
| `royalstar` |
| `shiverarrow` |
| `smallearth` |
| `smallice` |
| `smallstone` |
| `sniperarrow` |
| `snowball` |
| `spear` |
| `spectralbolt` |
| `suddendeath` |
| `tarsalarrow` |
| `throwingknife` |
| `throwingstar` |
| `vortexbolt` |

---

## slotType

Restrição de slot de equipamento (usado quando o item não segue o slot padrão).

| Valor | Descrição |
|---|---|
| `right-hand` | Apenas mão direita |
| `two-handed` | Duas mãos |

---

## wandType

Elemento do wand ou rod (determina o tipo de dano mágico).

| Valor |
|---|
| `death` |
| `earth` |
| `energy` |
| `fire` |
| `ice` |

---

## eventType

Usado em tiles/objetos com comportamento de evento, não em itens equipáveis propriamente.

| Valor | Descrição |
|---|---|
| `stepin` | Ativa ao pisar |
| `additem` | Ativa ao colocar item |
