# Análise de Atributos — Items Equipáveis

Arquivo fonte: `data/items/items.xml`
**Total analisado: 1273 items equipáveis**

Critério de seleção: items com `primarytype` em categoria equipável, ou com `weaponType`/`slotType` definido.

---

## Categorias equipáveis (`primarytype`)

`ammunition`, `amulets and necklaces`, `armors`, `axe weapons`, `boots`, `club weapons`,
`distance weapons`, `exercise weapons`, `helmets`, `legs`, `quivers`, `rings`, `rods`,
`shields`, `spellbooks`, `sword weapons`, `training weapons`, `wands`

---

## Atributos Comuns (presentes em ≥90% dos items)

| Atributo | Cobertura | Valores |
|---|---|---|
| `weight` | 99.2% | numérico |
| `primarytype` | 93.4% | ver categorias acima |
| `script` | 90.7% | `moveevent`, `moveevent;weapon` |
| `slot` | 90.7% | `head`, `armor`, `legs`, `feet`, `hand`, `ammo`, `ring`, `necklace`, `two-handed` |

---

## Atributos Variáveis

### Requisitos de Uso

| Atributo | Cobertura | Valores |
|---|---|---|
| `level` | 50.5% | numérico (1–600+) |
| `vocation` | 37.1% | `Knight;true`, `Paladin;true`, `Druid;true`, `Sorcerer;true`, combos, `None;true` |
| `unproperly` | 28.2% | `true` — penaliza se equipado sem vocation/level adequado |

### Combate

| Atributo | Cobertura | Valores |
|---|---|---|
| `attack` | 43.2% | numérico |
| `defense` | 44.6% | numérico |
| `armor` | 24.0% | numérico |
| `extradef` | 11.4% | numérico (pode ser negativo) |
| `range` | 11.8% | `3`–`7` |
| `hitchance` | 3.4% | numérico (pode ser negativo) |
| `maxhitchance` | 3.0% | numérico (40–100) |
| `cleavepercent` | 0.5% | numérico |
| `reflectdamage` | 0.2% | numérico |

### Tipo de Arma / Projétil

| Atributo | Cobertura | Valores |
|---|---|---|
| `weaponType` | 56.1% | `sword`, `axe`, `club`, `distance`, `wand`, `shield`, `spellbook`, `missile`, `ammo`, `ammunition` |
| `slotType` | 13.0% | `right-hand`, `two-handed` |
| `shootType` | 7.6% | 43 valores (ver [type-attributes.md](type-attributes.md)) |
| `wandType` | 4.4% | `fire`, `energy`, `ice`, `earth`, `death` |
| `ammotype` | 5.7% | `arrow`, `bolt` |
| `fromDamage` | 4.4% | numérico (dano mínimo de wand/rod) |
| `toDamage` | 4.4% | numérico (dano máximo de wand/rod) |
| `mana` | 4.4% | numérico (custo de mana por disparo) |
| `action` | 6.8% | `removecharge`, `removecount` |
| `charges` | 4.0% | numérico |

### Imbuement Slots

O valor `3` representa o número de slots daquele tipo disponíveis no item.

| Atributo | Cobertura | Valores |
|---|---|---|
| `imbuementslot` | 31.6% | `1`, `2`, `3` |
| `mana leech` | 21.2% | `3` |
| `life leech` | 20.1% | `3` |
| `critical hit` | 17.4% | `3` |
| `elemental damage` | 12.3% | `3` |
| `elemental protection holy` | 7.5% | `3` |
| `elemental protection death` | 7.2% | `3` |
| `elemental protection ice` | 7.2% | `3` |
| `elemental protection energy` | 7.0% | `3` |
| `elemental protection earth` | 6.8% | `3` |
| `elemental protection fire` | 6.7% | `3` |
| `skillboost shielding` | 6.9% | `3` |
| `skillboost club` | 6.8% | `3` |
| `skillboost sword` | 6.5% | `3` |
| `skillboost axe` | 6.3% | `3` |
| `skillboost distance` | 5.4% | `3` |
| `skillboost magic level` | 3.6% | `2`, `3` |
| `increase speed` | 2.0% | `3`, `10` |

### Bônus de Skills

| Atributo | Cobertura | Valores |
|---|---|---|
| `magiclevelpoints` | 8.3% | `1`–`5` |
| `skilldist` | 3.7% | `1`–`4` |
| `skillsword` | 3.0% | `1`–`5` |
| `skillaxe` | 2.8% | `1`–`5` |
| `skillclub` | 2.8% | `1`–`5` |
| `skillshield` | 0.8% | `-10`–`4` |
| `skillfist` | 0.1% | `6` |
| `firemagiclevelpoints` | 0.7% | `1`, `2` |
| `energymagiclevelpoints` | 0.7% | `1`, `2` |
| `healingmagiclevelpoints` | 0.7% | `1`, `2` |
| `icemagiclevelpoints` | 0.3% | `1`, `2` |
| `holymagiclevelpoints` | 0.4% | `1` |
| `earthmagiclevelpoints` | 0.2% | `1` |
| `deathmagiclevelpoints` | 0.2% | `1` |

### Absorção Elemental

| Atributo | Cobertura | Valores |
|---|---|---|
| `absorbpercentphysical` | 6.7% | numérico (pode ser negativo) |
| `absorbpercentfire` | 6.3% | numérico (pode ser negativo) |
| `absorbpercentpoison` | 5.8% | numérico (pode ser negativo) |
| `absorbpercentice` | 5.7% | numérico (pode ser negativo) |
| `absorbpercentenergy` | 5.3% | numérico (pode ser negativo) |
| `absorbpercentdeath` | 2.7% | numérico |
| `absorbpercentholy` | 1.0% | numérico (pode ser negativo) |
| `absorbpercentearth` | 1.0% | numérico |
| `absorbpercentmanadrain` | 0.3% | `5`, `10`, `15`, `20` |
| `absorbpercentdrown` | 0.2% | `100` |
| `absorbpercentlifedrain` | 0.1% | `20` |

### Dano Elemental Bônus (armas)

| Atributo | Cobertura | Valores |
|---|---|---|
| `elementfire` | 2.4% | numérico |
| `elementearth` | 2.4% | numérico |
| `elementice` | 2.0% | numérico |
| `elementenergy` | 1.7% | numérico |
| `elementdeath` | 0.5% | numérico |

### Critical Hit

| Atributo | Cobertura | Valores |
|---|---|---|
| `criticalhitchance` | 1.6% | `1000` |
| `criticalhitdamage` | 1.9% | `500`, `1200`, `1000`, `2500`, `3500` |

### Perfect Shot

| Atributo | Cobertura | Valores |
|---|---|---|
| `perfectshotrange` | 0.3% | `3`, `4` |
| `perfectshotdamage` | 0.2% | `20`, `65` |

### Life/Mana Leech Direto

| Atributo | Cobertura | Valores |
|---|---|---|
| `lifeleechchance` | 0.5% | `100` |
| `lifeleechamount` | 0.5% | `500`, `1800` |
| `manaleechchance` | 0.5% | `100` |
| `manaleechamount` | 0.5% | `100`, `300` |

### Regeneração (anéis/amulets)

| Atributo | Cobertura | Valores |
|---|---|---|
| `healthgain` | 0.2% | `1`, `2`, `3` |
| `healthticks` | 0.2% | `3000`, `6000` |
| `managain` | 0.2% | `4`, `8`, `12` |
| `manaticks` | 0.2% | `3000`, `6000` |

### Velocidade

| Atributo | Cobertura | Valores |
|---|---|---|
| `speed` | 1.9% | numérico (pode ser negativo) |

### Transformação ao Equipar/Desequipar

| Atributo | Cobertura | Valores |
|---|---|---|
| `transformequipto` / `transformEquipTo` | 1.9% | item ID numérico |
| `transformdeequipto` / `transformDeEquipTo` | 1.8% | item ID numérico |

### Decay / Duração

| Atributo | Cobertura | Valores |
|---|---|---|
| `duration` | 3.5% | numérico (segundos) |
| `decayTo` / `decayto` | 3.3% | item ID numérico |
| `stopduration` | 2.1% | `0`, `1` |
| `showduration` | 4.2% | `0`, `1` |
| `showCharges` | 3.7% | `1` |
| `showAttributes` / `showattributes` | 6.6% | `1` |

### Magic Shield

| Atributo | Cobertura | Valores |
|---|---|---|
| `magicshieldCapacityflat` | 0.2% | `80` |
| `magicshieldCapacitypercent` | 0.2% | `8` |

### Containers Equipáveis (quivers, spellbooks)

| Atributo | Cobertura | Valores |
|---|---|---|
| `containersize` | 0.5% | `6`, `8`, `12` |
| `writeable` | 0.4% | `1` |
| `maxtextlen` | 0.4% | `99`, `149` |

### Especiais / Raros

| Atributo | Cobertura | Valores |
|---|---|---|
| `invisible` | 0.1% | `1` |
| `manashield` | 0.1% | `1` |
| `suppressdrunk` | 0.1% | `1` |
| `chain` | 0.1% | `0.9` |
| `fieldabsorbpercentfire` | 0.1% | `90` |

---

## Inconsistências de Casing no XML

Os pares abaixo representam o mesmo atributo com grafias diferentes — vale normalizar no XML ou no parser:

| Variante A | Variante B |
|---|---|
| `showAttributes` | `showattributes` |
| `transformEquipTo` | `transformequipto` |
| `transformDeEquipTo` | `transformdeequipto` |
| `hitChance` | `hitchance` |
| `perfectShotDamage` | `perfectshotdamage` |
| `decayTo` | `decayto` |
