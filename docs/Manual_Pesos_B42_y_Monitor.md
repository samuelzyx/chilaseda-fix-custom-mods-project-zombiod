# Manual de pesos y verificación

**Project Zomboid Build 42 · Partida Sandbox de Jill**<br>
**Última actualización:** 9 de noviembre de 2026

Esta tabla reúne los pesos base revisados y los objetivos de los parches locales. El monitor compara el peso observado en las ubicaciones accesibles con la meta correspondiente.

Para `Base.WaterDispenserBottle`, el agua pesa aproximadamente 1 kg/L (USGS: https://www.usgs.gov/water-science-school/science/facts-about-water). El envase vacío de 0.80 kg es realista: Parker Plastics publica 677–700 g para un garrafón reutilizable de 5 galones (https://www.parker-plastics.com/home-office-water/), y FaboCaps publica 750–820 g para uno de policarbonato de 18.9 L (https://fabocaps.co.za/products/bottles). Como el objeto B42 admite 15 L, los objetivos quedan en 0.80 kg vacío, aproximadamente 12.05 kg con 11.25 L (~3/4) y 15.80 kg lleno. El recuerdo de Chila sobre el nivel es aproximado; el log 1.6.3 solo anotó 2.00 kg y no guardó el volumen, así que no permite validar cuál estado tenía el objeto.

Los valores base B42 de `Base.LargeAnimalBone` (2.00 kg) y `Base.SmallAnimalBone` (0.30 kg) describen el juego, no una medicion de Jill. `LargeAnimalBone` queda en 0.70 kg: piezas de femur bovino para venta rondan 1.5 lb (0.68 kg; https://readfieldmeats.com/store/product/beef-femur-bones), redondeado a 0.70 y dentro del rango 0.6-0.8 kg de la nota. `SmallAnimalBone` queda en 0.10 kg como porcion/paquete de piezas pequenas, no un hueso individual. `SharpBoneFragment` queda en 0.01 kg como estimacion de fragmento pequeno. El Smithsonian documenta fragmentos de punzones oseos de varios centimetros y pesos de conjunto en decenas de gramos (https://www.si.edu/object/bone-awl-fragments%3Anmnhanthropology_8200757); 10 g es una meta conservadora para una pieza pequena. `PetrolCan` usa 1.60 kg vacio + 0.75 kg/L de gasolina; Aral publica 0.720-0.775 kg/L a 15 C (https://mein.aral.de/kontakt/faqs/kraftstoff-tanken/tankstellenfinder-allgemein/was-wiegt-ein-liter-benzin-bzw-diesel). La etiqueta EPA reporta 9 g por cada pad individual (https://www3.epa.gov/pesticides/chem_search/ppls/098774-00003-20240125.pdf); para las cinco cargas de `Base.AlcoholWipes` se estima 0.05 kg de contenido más 0.01 kg de empaque. Un bidon de 10 L pesa 9.10 kg lleno y 7.225 kg a 3/4.

## Alcance de la auditoría completa

El objetivo es cubrir todos los objetos registrables de la instalacion de Jill: definiciones vanilla y de cada mod activo, incluidos animales/cadaveres, resultados de rebuscar, objetos procesados y objetos cuyo peso cambia por contenido o estado. El log de Jill del 29/10 enumera 10,884 definiciones y confirma stack 100/OK; eso no comprueba que cada peso sea realista ni que tenga una meta fisica revisada. Weight Monitor 1.7.0 anadio un catalogo de peso declarado/actual/meta/cobertura por definicion; 1.7.1 sincroniza la meta del diario, 1.7.2 revisa 12 marcadores visuales de peso base cero, 1.7.3 agrega la meta del cartucho .22 LR y 1.7.4 revisa 21 pesos base de mochilas Authentic Z, 1.7.5 revisa 578 auxiliares de masa cero, 1.7.6 agrega la meta de la pluma de tren de pavo real y 1.7.7 alinea el catálogo con las metas explícitas del parche y 1.7.8 agrega SugarPacket y revisa PeafowlFeather; 1.7.9 añade tres útiles de escritura y 1.8.0 agregó `Base.Acorn` y `Base.Battery`; 1.8.1 corrige la bellota a meta dinámica por porción; 1.8.2 incorpora llaves y curita; 1.8.3 añade linterna de mano, 1.8.4 fija el reloj digital y 1.8.5 incorpora cueros bovinos, 1.8.6 pieles de oveja, 1.8.7 pieles porcinas y 1.8.8 corrige la retención húmeda porcina y 1.8.9 añade metas para pieles adultas de conejo y corrige 48 metas verdes adultas; 1.9.0 sincroniza cinco bandoleros vanilla a 0.40 kg; 1.9.1 añade etapas a 64 cueros de becerro; 1.9.2 sincroniza 56 pieles de cordero y 24 de oveja esquilada; 1.9.3 añade etapas de 60 pieles de cerdito y 1.9.4 estima la etapa húmeda de 48 pieles adultas de conejo. El inventario estatico completo esta en [PesoCatalogo_Jill_Auditoria.csv](PesoCatalogo_Jill_Auditoria.csv): 10,884 IDs, 1,349 con metas fijas/grupales, 612 pesos base revisados, 5 dinamicos y 8,918 sin clasificar. Las 21 entradas Authentic Z no localizadas inicialmente ya se vincularon a sus definiciones en scripts de recetas. `MAPPED` significa que existe un override, no que ya este respaldado por una referencia fisica; `UNMAPPED` conserva el peso de juego/mod pendiente de auditoria; `DYNAMIC` necesita contrastarse con la instancia. Las tablas existentes son cobertura parcial, no el catalogo completo.


### Bandoleros de munición vanilla

Cinco variantes (`Base.AmmoStrap_Brown_Bullets`, `Base.AmmoStrap_Brown_Shells`, `Base.AmmoStrap_Bullets`, `Base.AmmoStrap_Bullets_308` y `Base.AmmoStrap_Shells`) no declaran masa propia en las definiciones generadas de `container.txt`. Se les asigna 0.40 kg como bandolera vacía: queda entre un cinturón Garand de 0.55 kg y bandoleras portacartuchos comerciales de 0.335–0.45 kg. `Base.AmmoStraps` de Workshop ya declara 0.40 kg y sirve como comprobación interna de escala, no como fuente física independiente. Referencias: [cinturón Garand de 550 g](https://www.re-enactmentshop.com/shop/battle/parts-and-accessories/cartridge-belt-garand/), [bandolera de escopeta de 335 g](https://www.thesurvivalisland.com/product/12-20-gauge-shotgun-bandolier/) y [bandolera de cuero de 450 g](https://ythobby.com/product/hunting-bandolier-shotgun-12-16-20-36-gauge-cartridges-holder-for-shooting-2/). VanillaWeightFix 1.4.16 y Weight Monitor 1.9.0 comparten la meta; falta lectura runtime posterior.

### Cueros adultos de vaca y toro (Animal Remaster)

Se asignan metas por etapa a 128 IDs activos (`Base.AMR_Hide_Cow_*` y `Base.AMR_Hide_Bull_*`): `*_Full` y `*_Fur` = 20 kg (cuero verde adulto, límite inferior de las clases bovinas de 20–60 kg); `*_Fur_Tan_Wet` = 16 kg (80% del verde, dentro del rango de 70–90% de peso que conserva el cuero bovino húmedo-salado); `*_Fur_Tan` = 8 kg (40% del verde, dentro del 35–45% que queda al secar). Las etapas y tags de los objetos del Workshop distinguen cuero completo/para suavizar, con pelo/para curtir, húmedo/para secar y curtido final. Los recortes `Medium` y `Small` siguen sin meta: no hay área o masa de corte definida que permita asignarles un peso físico verificable.

Referencias: [FAO, Hides and Skins](https://www.fao.org/4/x6552e/X6552E10.htm) informa 18 kg promedio de cuero verde bovino y 70–90% de retención tras salado húmedo; [ISO/TR 2822-2 extracto técnico](https://www.standards.iteh.ai/catalog/standards/iso/bc4c7861-96ad-4905-b6e5-1412f345c9c1/iso-tr-2822-2-2017) clasifica cueros adultos bovinos en clases desde 20 kg; [Weight and area of leather](https://eopcw.com/find/downloadFiles/159) informa pérdida de 55–65% al secar. Se usa 20 kg como objetivo adulto conservador, 16 kg para la etapa húmeda y 8 kg seca. VanillaWeightFix 1.4.11 y Weight Monitor 1.8.5 comparten las reglas. Aún falta lectura runtime posterior a esos mods.

### Cueros de becerro (Animal Remaster)

Se asignan metas por etapa a 64 pieles `Base.AMR_Hide_Calf_*`: 16 IDs `*_Full` y 16 `*_Fur` = 12.30 kg; 16 `*_Fur_Tan_Wet` = 9.84 kg; 16 `*_Fur_Tan` = 4.92 kg. La definición B42 `CowDefinitions.lua` fija 60–350 kg para `cowcalf`; el punto medio (205 kg) multiplicado por el límite conservador de 6% de peso vivo para cuero bovino produce 12.3 kg verde. Para húmedo se usa 80% de retención (dentro de 70–90%); para seco 40% (pérdida de 60%). Referencias: [FAO, rendimientos de cueros verdes y conservación](https://www.fao.org/4/x6552e/X6552E10.htm) (cattle 6–8% del peso vivo; 70–90% tras salado húmedo) y [Weight and area of leather](https://eopcw.com/find/downloadFiles/159) (55–65% de pérdida al secar). VanillaWeightFix 1.4.17 y Weight Monitor 1.9.1 comparten los objetivos; sin lectura runtime posterior.

### Pieles adultas de ovejas (Animal Remaster)

Se asignan metas por etapa a 96 IDs de pieles adultas no esquiladas de Jacob, Dorper, Icelandic y Shetland. `*_Full` y `*_Fur` usan 6.00 kg para Jacob/Dorper/Icelandic y 4.00 kg para Shetland; `*_Fur_Tan_Wet` usa 80% (4.80/3.20 kg), y `*_Fur_Tan` usa 40% (2.40/1.60 kg). FAO informa 6 kg para piel verde de oveja grande y 4 kg para oveja enana; para secado se aplica el rango de 55–65% de pérdida publicado para pieles. Dorper, Jacob e Icelandic son las categorías mayores frente a Shetland según sus estándares de masa adulta (enlaces abajo); el peso por raza es una aproximación de clase, no medición de una oveja individual. Los IDs de piel esquilada adulta se documentan en la siguiente sección; las pieles de cordero y los recortes `Small` también se separan por su etapa y tamaño.

Referencias: [FAO, conversión de productos pecuarios](https://www.fao.org/fileadmin/templates/ess/documents/methodology/tcf.pdf) (4.5 kg promedio de piel fresca de oveja); [FAO, faena de pequeños rumiantes](https://www.fao.org/4/x6552e/X6552E10.htm) (6 kg oveja grande, 4 kg oveja enana); [peso de pieles con lana y deslanadas](https://www.mla.com.au/shorturls/lamb-co-products-compendium/) (5–6 kg con lana, 2–3 kg tras retirar lana); [Dorper](https://www.dorper-hairsheep.com/dorper/rassenstandart/); [Jacob](https://livestockconservancy.org/jacob-american-sheep/); [Icelandic](https://www.isbona.com/index.php/about-icelandic-sheep/breed-standards); [Shetland](https://schafe-sind-toll.com/shetlandschaf/). Weight Monitor 1.8.6 y VanillaWeightFix 1.4.12 comparten los objetivos. Pendiente una sesión runtime posterior a esas versiones.

### Pieles de cordero y ovejas esquiladas (Animal Remaster)

Se fijan metas a 56 pieles de cordero: Jacob, Dorper, Icelandic y las variantes genéricas BlackFace/White usan 4.95 kg verde (`Full`/`Fur`), 3.96 kg húmedo y 1.98 kg curtido seco; Shetland usa 4.00, 3.20 y 1.60 kg. B42 define 20–70 kg para `lamb` (punto medio 45 kg); MLA informa 11% de peso vivo para piel no-Merino, equivalente a 4.95 kg. Shetland usa la clase FAO de oveja enana (4 kg). Los 24 IDs de piel adulta esquilada reciben 2.5 kg verde (punto medio de 2–3 kg de piel deslanada), 2.0 kg húmeda y 1.0 kg curtida seca. MLA contrasta piel Merino con lana de 5–6 kg frente a 2–3 kg tras retirar la lana. Las etapas húmedas usan 80% del peso verde; el curtido final 40%, consistente con el rango de pérdida 55–65% de la referencia de cuero. Permanecen sin meta 6 variantes `Small` de piel esquilada, 28 otros cortes pequeños y 16 pieles genéricas sin raza o dimensión definida.

Referencias: [MLA, Lamb co-products compendium](https://www.mla.com.au/shorturls/lamb-co-products-compendium/) (piel ovina promedio 13% del peso vivo; non-Merino 11%; piel Merino con lana 5–6 kg y deslanada 2–3 kg); [FAO, pequeños rumiantes](https://www.fao.org/4/x6552e/X6552E10.htm) (4 kg para oveja enana y pérdidas por curado); [Weight and area of leather](https://eopcw.com/find/downloadFiles/159) (55–65% de pérdida al secar). B42 `SheepDefinitions.lua` define `lamb` en 20–70 kg. VanillaWeightFix 1.4.18 y Weight Monitor 1.9.2 sincronizan estas 80 metas; falta lectura runtime posterior.

### Pieles adultas de conejo (Animal Remaster)

Se asignan objetivos a 144 IDs de piel de conejo adulto: 48 variantes `*_Full` y 48 `*_Fur` = 0.43 kg; 48 variantes `*_Fur_Tan` = 0.225 kg. Las metas previas de 48 pieles adultas `Full` se corrigieron de 0.25 a 0.43 kg. Un estudio de 22 conejos informa piel promedio de 428 g (rango 385–480 g), usado como analogía para el cuero verde; la FAO clasifica pieles secas de conejo como ligeras (100–140 g), regulares (150–210 g) y pesadas (250–350 g). Se elige 225 g como estimación conservadora cercana al límite inferior de la clase pesada porque el mod no identifica la clase de pelt. Esta es una estimación de clase, no masa medida de cada animal. Las 48 variantes adultas `*_Fur_Tan_Wet` reciben 0.384 kg: el estudio de piel natural de conejo mide 64.36% de humedad y el cuero semiterminado 31.76%; conservando la materia seca implícita en 0.225 kg seco, y usando 60% de humedad para la etapa wet-blue, el cálculo da 0.384 kg. Es una estimación de proceso, no pesaje directo de cada pelt. Las 96 pieles juveniles (24 variantes por cuatro etapas) reciben 0.30 kg verdes (`Full`/`Fur`), 0.27 kg húmedas y 0.16 kg curtidas secas. El objetivo verde usa el pelt de 299 g reportado para conejos de ocho semanas; el wet y el seco escalan las proporciones adulta medida/documentada (0.384/0.43 y 0.225/0.43). Se reemplazó la meta anterior de 0.10 kg para `Full`, que no tenía fuente. FAO sitúa la madurez del manto infantil cerca de nueve semanas; la edad exacta de cada objeto del mod no está especificada, así que ocho semanas es un análogo explícito.

Referencias: [estudio de participación de partes en carne de conejo](https://www.researchgate.net/publication/266092559_Participation_of_main_parts_and_internal_organs_in_rabbit_meat) (428 g de piel promedio, 385–480 g); [FAO, Rabbit husbandry](https://www.fao.org/4/t1690e/t1690e.pdf) (clases de piel seca por peso). VanillaWeightFix 1.4.15 y Weight Monitor 1.8.9 comparten las metas; todavía no hay lectura runtime posterior.

### Pieles adultas de cerdo (Animal Remaster)

Se asignan objetivos por etapa a 152 IDs de pieles adultas `Pig` y `Boar` (Berkshire, Belted, Old Spots y Russet): `*_Full` y `*_Fur` = 14 kg; `*_Fur_Tan_Wet` = 13.6 kg; `*_Fur_Tan` = 5.6 kg. La definición animal de B42 establece 115–350 kg para sow/boar; usando el punto medio (232.5 kg), la extensión de University of Maine estima la piel en 6% del peso vivo: 13.95 kg, redondeado a 14 kg. Para la etapa húmeda se aplica una pérdida de 2–4% reportada para piel porcina húmedo-salada (14 × 0.97 ≈ 13.6 kg). La piel seca queda en 40% del verde (5.6 kg), dentro de la pérdida de 55–65% documentada para pieles secas. Los lechones, variantes FarmPig no equivalentes y recortes `Small` siguen pendientes: falta una masa por edad o tamaño de corte verificable.

Referencias: [University of Maine Cooperative Extension](https://extension.umaine.edu/publications/1073e/) estima la piel en ~6% del peso vivo y un market hog promedio de 285 lb; el archivo local B42 `media/lua/shared/Definitions/animal/PigDefinitions.lua` define `minWeight=115` y `maxWeight=350` para sow y boar; [Weight and area of leather](https://eopcw.com/find/downloadFiles/159) reporta 2–4% de pérdida húmedo-salada en piel porcina y 55–65% de pérdida para pieles secas. VanillaWeightFix 1.4.14 y Weight Monitor 1.8.8 comparten objetivos. Sin lectura runtime posterior.
## Tabla de pesos

`Base.22Bullets`, anadido por Extended Vanilla Weapons, estaba definido en 0.005 kg. El manual oficial estadounidense TM 9-280 da 53.5 grains (~3.47 g) para el cartucho .22 LR completo ([registro GovInfo](https://www.govinfo.gov/content/pkg/GOVPUB-W-9ff7daf9acdf2842ebbebd9ef3f9ecc9/pdf/GOVPUB-W-9ff7daf9acdf2842ebbebd9ef3f9ecc9.pdf)); el parche lo redondea a 0.0035 kg. El Monitor 1.6.3 lo incluyo en su catalogo de stack, no en una lectura de peso. VanillaWeightFix 1.4.3 y Weight Monitor 1.7.7 comparten el objetivo; no hay lectura runtime posterior.

`AMRBirds321.PeafowlTrainFeather` sube de 0.001 a 0.0022 kg: un estudio de campo de pavo real azul de la India midio 2.2 g como promedio de las plumas oculares medianas del tren; se usa ese grupo como analogia para la pluma de tren generica del mod ([estudio, IJARBS 2020](https://ijarbs.com/pdfcopy/2020/mar2020/ijarbs9.pdf)). La definicion llega de Animal Remaster (Workshop 3819478254); VanillaWeightFix 1.4.4 carga despues de `AnimalRemasterApproved` y Weight Monitor 1.7.8 comparte la meta. Sin lectura runtime posterior.

`AMRBirds321.PeafowlFeather` conserva su base de 0.001 kg: el mismo estudio midio un promedio de 0.95 g para una pluma de cola individual, cercano a los 1.00 g del script. Weight Monitor 1.7.8 la marca `BASE_OK` si el peso cargado sigue en 0.001 kg.

`Base.SugarPacket` baja de 0.005 a 0.004 kg. La ficha de Holliston especifica paquetes individuales con 3.5 g de azúcar; se redondea a 4 g para incluir el sobre de papel ([presentación de 3.5 g de Holliston](https://hollistons.com/product/sugar-packets/)). VanillaWeightFix 1.4.6 y Weight Monitor 1.8.0 comparten la meta.

`Base.BluePen` y `Base.RedPen` bajan de 0.1 a 0.006 kg según la masa publicada de BIC Cristal (5.58–5.6 g). `Base.Pencil` baja de 0.1 a 0.005 kg según lápices de madera de 5.0–5.4 g ([ficha de producto](https://odmultimedia.eu/Immagini/Schede_Fornitore/95595.pdf), [BIC Japan](https://bic-japan.co.jp/products/stationery/ballpen_oil_based_cap/)); OHTO y rOtring documentan lápices en 5.0–5.4 g ([OHTO](https://www.ohto.co.jp/english/pdf/WoodenBodyProductsForPrivateBrand_2023_V2.pdf), [rOtring](https://www.rotring.ro/instrumente-de-scris-desen-grafica-si/woodcase-pencil/core-blue/)). VanillaWeightFix 1.4.7 y Weight Monitor 1.8.1 comparten esas metas. BIC publica [5.58 g](https://odmultimedia.eu/Immagini/Schede_Fornitore/95595.pdf) y [5.6 g](https://bic-japan.co.jp/products/stationery/ballpen_oil_based_cap/) por bolígrafo; OHTO publica [5.4 g](https://www.ohto.co.jp/english/pdf/WoodenBodyProductsForPrivateBrand_2023_V2.pdf) para su lápiz de madera.

`ThisIsYourLife.PreservedJournal` aparecia con peso definido de 0 kg y Jill lo cargo en una rinonera con `actual=0` (Weight Monitor 1.6.1). Se asigna 0.25 kg como aproximacion para un diario encuadernado de tamano no especificado: LEUCHTTURM1917 publica 0.15 kg para una libreta hardcover A6 y 0.42 kg para A5 de 251 paginas ([pesos A6-A5](https://www.leuchtturm1917.us/products/hardcover-notebook?variant=48072863252725)); otra libreta A5 de 251 paginas pesa 0.423 kg ([Bauhaus A5](https://www.leuchtturm1917.us/products/bauhaus-edition-notebook)). El objetivo esta en VanillaWeightFix 1.4.3 y Weight Monitor 1.7.7; falta una lectura posterior al cambio.

### Mochilas de mejora de Authentic Z

Las 21 entradas `AuthenticZClothing.Bag_*_Tier_*` estan declaradas en los scripts de recetas de mejora de mochilas de Workshop 2335368829, con `Weight=1` y capacidad de 19. Se conserva el peso base de 1.00 kg como realista para un bolso tipo duffel de esa capacidad: productos comparables pesan 0.99 kg para un duffel de viaje de 31 L ([Swiss Military](https://www.swissmilitaryindia.com/products/java-duffle-bag-with-spacious-main-compartment-31l-db34)), 0.9 kg para un duffel militar de lona ([Army and Outdoors](https://www.armyandoutdoors.com.au/products/british-olive-drab-duffel-bag)) y alrededor de 1 kg para una bolsa de asalto medico vacia ([MED-TAC](https://tactical-medicine.com/en-gb/products/tacmed-r-aid-medic-assault-bag)). Weight Monitor 1.7.4 las marca `BASE_OK` solo si la definicion cargada sigue en 1.00 kg; es revision de la definicion, no lectura de una instancia de Jill.

| Nombre / grupo | ID tecnico | Base (kg) | Meta (kg) | Observado (kg) | Estado |
|---|---|---:|---:|---:|---|
| Duffel festivo Tier 1 | `AuthenticZClothing.Bag_DuffelBag_Festive_Tier_1` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel festivo Tier 2 | `AuthenticZClothing.Bag_DuffelBag_Festive_Tier_2` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel festivo Tier 3 | `AuthenticZClothing.Bag_DuffelBag_Festive_Tier_3` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel gris Tier 1 | `AuthenticZClothing.Bag_DuffelBagGrey_Tier_1` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel gris Tier 2 | `AuthenticZClothing.Bag_DuffelBagGrey_Tier_2` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel gris Tier 3 | `AuthenticZClothing.Bag_DuffelBagGrey_Tier_3` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel medico Tier 1 | `AuthenticZClothing.Bag_MedicalBag_Tier_1` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel medico Tier 2 | `AuthenticZClothing.Bag_MedicalBag_Tier_2` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel medico Tier 3 | `AuthenticZClothing.Bag_MedicalBag_Tier_3` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel militar Tier 1 | `AuthenticZClothing.Bag_Military_Tier_1` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel militar Tier 2 | `AuthenticZClothing.Bag_Military_Tier_2` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel militar Tier 3 | `AuthenticZClothing.Bag_Military_Tier_3` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel policial Tier 1 | `AuthenticZClothing.Bag_Police_Tier_1` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel policial Tier 2 | `AuthenticZClothing.Bag_Police_Tier_2` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel policial Tier 3 | `AuthenticZClothing.Bag_Police_Tier_3` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel de sheriff Tier 1 | `AuthenticZClothing.Bag_Sheriff_Tier_1` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel de sheriff Tier 2 | `AuthenticZClothing.Bag_Sheriff_Tier_2` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel de sheriff Tier 3 | `AuthenticZClothing.Bag_Sheriff_Tier_3` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel SWAT Tier 1 | `AuthenticZClothing.Bag_SWAT_Tier_1` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel SWAT Tier 2 | `AuthenticZClothing.Bag_SWAT_Tier_2` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |
| Duffel SWAT Tier 3 | `AuthenticZClothing.Bag_SWAT_Tier_3` | 1.00 | 1.00 | — | Base revisada; sin registro runtime |

Los objetivos estan en kg por unidad. `Observado` solo se rellena con una medicion de monitor o un dato reportado por Chila; `Estado` usa las etiquetas del Weight Monitor. `Sin registro` significa que el log aun no contiene una medicion de ese tipo en Jill con la version indicada.

| Nombre / grupo | ID tecnico | Base (kg) | Meta (kg) | Observado (kg) | Estado |
|---|---|---:|---:|---:|---|
| Banderas y estandartes | `DGVFlags.Flag_*` / `DGVFlags.Banner_*` | 0.30 | 0.15 | — | Sin registro |
| Posters | `DGVPosters.*` | 0.20 | 0.05 | 0.05 (prueba previa) | OK (prueba previa) |
| Diario preservado de This Is Your Life | `ThisIsYourLife.PreservedJournal` | 0.00 | 0.25 | Sin registro en 1.6.3; historico 0.00 kg (1, version 1.6.1) | Sin registro |
| Cartucho .22 LR | `Base.22Bullets` | 0.005 | 0.0035 | Sin registro en 1.6.3 | Sin registro |
| Pluma mediana de tren de pavo real | `AMRBirds321.PeafowlTrainFeather` | 0.001 | 0.0022 | — | Sin registro runtime |
| Pluma de cola de pavo real | `AMRBirds321.PeafowlFeather` | 0.001 | 0.001 | — | Base revisada; sin lectura runtime |
| Paquete de azúcar | `Base.SugarPacket` | 0.005 | 0.004 | — | Sin registro runtime |
| Bellota | `Base.Acorn` | 0.1 | 0.0057 × fracción restante | Jill 08/11 23:11:14 -06:00, monitor 1.9.7: actual 0.069, total 0.630 kg/9, target 0.0057; `REVISAR`, `tetrisStack=100`, sin dato scriptStack. `Visto` posterior con count=0 conserva 0.069. Causa localizada: el fix enumeraba contenedores cercanos sin refrescar páginas de inventario/botín, a diferencia del monitor; el parche ya refresca ambas antes de esa lista. Lectura del 07/11: mismos pesos; 06/11: 0.078, total 0.971 kg/17. | REVISAR hasta confirmar que el próximo log registre la instancia en 0.0057 kg y que la recorra el parche. 69 g supera ampliamente los 1.48–7.71 g de un estudio de *Q. variabilis*. |
| Machete | `Base.Machete` | 2.0 | 0.71 | Jill 08/11 21:41:23 -06:00, monitor 1.9.7: actual 2, total 4 kg/2; `REVISAR`, `tetrisStack=100`, sin dato scriptStack. `Visto` posterior con count=0. | Meta física de machete completo: 0.71 kg ([UNIDO, diseño/fabricación](https://downloads.unido.org/ot/47/92/4792012/10001-15000_11218E.pdf)). |
| Hoja de machete sin espiga | `Base.MacheteBlade_NoTang` | 2.0 | 0.48 | Jill 08/11 18:27:10 -06:00, monitor 1.9.7: actual 2 kg, count=0 en último `Visto`; `REVISAR` previo count=1, total 2 kg; `tetrisStack=100`, sin dato scriptStack. | Estimación por analogía con los 0.48 kg del cuerpo de machete en la referencia UNIDO; la pieza sin espiga no equivale a un machete completo. |
| Machete rudimentario | `Base.Machete_Crude` | 2.0 | 0.71 | Sin registro en el monitor de la sesión 08/11. | Estimación por analogía con el machete completo de 0.71 kg de UNIDO. |
| Batería AA | `Base.Battery` | 0.1 | 0.023 | 0.025 | Energizer E91, 23 g ([ficha](https://data.energizer.com/pdfs/e91_max_na.pdf)) |
| Bolígrafo azul | `Base.BluePen` | 0.1 | 0.006 | — | BIC Cristal 5.58–5.6 g; analogía |
| Bolígrafo rojo | `Base.RedPen` | 0.1 | 0.006 | — | BIC Cristal 5.58–5.6 g; analogía |
| Lápiz | `Base.Pencil` | 0.1 | 0.005 | — | Lápiz de madera OHTO, 5.4 g |
| Llave de casa | `Base.Key1` | 0.05 | 0.009 | 0 | Blanco SC1: 8.4 g aprox. por unidad incluyendo embalaje ([paquete de 50](https://www.millsupply.co/hardware/keys-and-assys/key-blanks/cylinder/all-cylinder-blanks/kaba-ilco-sc1-br-5-pin-schlage-sc1-key-blank-brass-50-box-m34136)) |
| Llave de auto | `Base.CarKey` | 0.05 | 0.012 | 0 | Jill 07/11 19:37, monitor 1.9.7: actual/total 0 kg/1, target 0.012 kg; luego Visto. Llave SC1 decorada, 13.6 g ([producto](https://www.walmart.ca/en/ip/shiyou-Forged-Key-Shapes-Anchor-House-Key-Blank-SC1-1-Key-B304S-Schlage-SC1/2NN5ULGU7JLV)) |
| Curita | `Base.Bandaid` | 0.05 | 0.001 | 0.01 | Caja de 100 con envío 0.18 lb ≈0.82 g/unidad ([Band-Aid 100 ct](https://www.target.com/p/-/A-14796602)) |
| Linterna de mano | `Base.HandTorch` | 0.5 | 0.20 | 0.20 | Energizer 2-in-1: 117 g sin pilas + 4 AA de 23 g ≈209 g ([ficha](https://data.energizer.com/pdfs/enfhh41e.pdf), [E91 AA](https://data.energizer.com/pdfs/e91_max_na.pdf)) |
| Reloj digital de vestir | `Base.WristWatch_Left_DigitalDress` | 0.1 | 0.021 | 0.03 | Casio F-91W, 21 g ([fabricante](https://www.casio.com/us/watches/casio/about/f-91w/)) |
| Portapapeles | `Base.Clipboard` | 1.00 | 0.25 | — | Sin registro |
| Periódico reciente | `Base.Newspaper_Recent` | 0.10 | 0.13 | 0.10 kg (1, Jill 02/11; log rotuló 1.9.3, `mod.info` decía 1.9.5; luego Visto count=0) | REVISAR hasta cargar meta; 130 g promedio ([Axel Springer](https://www.axelspringer.com/en/inside/newspapers-fresh-as-dew-and-still-fragrant)), newsprint 40–56 g/m² ([TIS](https://www.tis-gdv.de/tis_e/ware/papier/zeitung/zeitung-htm/)) |
| Revista “Alto Volador” | `Base.Magazine_Rich` | Sin dato (`scriptWeight=sin_dato`) | 0.10 | 0.10000000149 kg (1; Jill 08/11 17:19:11 -06:00, Weight Monitor 1.9.7; luego `Visto`, count=0) | REVISAR en la sesión 08/11 17:19:11 y 17:19:14 -06:00 porque entonces `target=sin_meta`. Meta estimada: revista A5 de 32 páginas ≈75.21 g ([muestra](https://staging.youloveprint.co.uk/magtest.html)) y revista de 58 páginas =172 g ([KANDY](https://www.brownsbfs.co.uk/Product/Magazine-Kandy/KANDY-Magazine-Spring-2025-Issue/9798349251597)); se propone 0.10 kg porque el formato y paginación de esta revista del juego no están documentados. La observación antecede a la meta: falta lectura posterior para confirmar `OK`. |
| Lupa | `Base.MagnifyingGlass` | 0.50 | 0.15 | — | Sin registro |
| Garrafón de dispensador | `Base.WaterDispenserBottle` | 2.00 | 0.80 vacío; 0.80 + litros de agua (máx. 15 L); 15.80 lleno | 2.059 kg/unidad; target 2.059 kg (1; Jill 30/10, monitor 1.9.3; contenido parcial) | OK |
| Toallitas con alcohol | `Base.AlcoholWipes` | 0.30 | 0.01 kg empaque + 0.05 × getUsedDelta (0.06 kg llena; 0.01 kg agotada; cinco pads de ~9 g cada uno, etiqueta EPA https://www3.epa.gov/pesticides/chem_search/ppls/098774-00003-20240125.pdf) | 0.10 kg/unidad (2; Jill 29/10, monitor 1.6.3; target=sin_meta, carga no registrada) | REVISAR (antes de 1.6.9) |
| Salvia mellifera (silvestre) | `Base.BlackSage` | 0.10 | 0.05 | 0.05 kg/unidad (17; Jill 30/10, monitor 1.9.3; target 0.05; stack 100/OK) | OK |
| Vidrio roto | `Base.BrokenGlass` | 0.50 | 0.05 | 0.05 kg/unidad (hasta 6; Jill 30/10, monitor 1.9.3; target 0.05; stack 100/OK) | OK |
| Cuchilla de vidrio | `Base.GlassShiv` | 0.50 | 0.10 | 0.10 kg/unidad (hasta 6; Jill 30/10, monitor 1.9.3; target 0.10; stack 100/OK) | OK |
| Esqueleto de venada cola blanca | `Base.CorpseAnimal` (`infecteddeerdoe` / `undeaddeerdoe`) | 0.10 | 24.80 (16% del peso medio de doe: 155 kg) | 24.80 kg (log Jill 29/10, animalType=infecteddeerdoe, target=24.8, stackStatus=OK) | OK |
| Hueso de animal | `Base.AnimalBone` | 1.50 | 0.175 | 1.50 kg/unidad (hasta 9; Jill 29/10, monitor 1.6.3; target=sin_meta) | REVISAR (antes de 1.2.6) |
| Katana rota | `Base.Katana_Broken` | 1.50 | 0.70 | 0.70 kg/unidad (1; Jill 30/10, monitor 1.9.3; target 0.70; stack 100/OK) | OK |
| Vara de madera | `Base.WoodenStick2` | 2.00 | 0.40 | 0.40 kg/unidad (1; Jill 30/10, monitor 1.9.3; target 0.40; stack 100/OK) | OK |
| Hueso grande de animal | `Base.LargeAnimalBone` | 2.00 | 0.70 | 2.00 kg por unidad (4 accesibles; log Jill 29/10; anterior a la meta; tetrisStack=100, stackStatus=OK) | REVISAR (meta nueva 1.4.0) |
| Hueso pequeño | `Base.SmallAnimalBone` | 0.30 | 0.10 | 0.30 kg por unidad (8 unidades; log Jill 29/10; anterior a la meta; tetrisStack=100, stackStatus=OK) | REVISAR (meta nueva 1.4.0) |
| Fragmento de hueso afilado | `Base.SharpBoneFragment` | 0.30 | 0.01 | — | Sin registro (meta nueva 1.4.0) |

### Capacidad del suelo

| Lugar | Base del juego | Objetivo local | Observado en Jill | Estado |
|---|---:|---:|---|---|
| Celda de suelo | 50 kg | 1000 kg | Sin registro; fix local 0.1.0 activado en el perfil Jill | Sin registro |
| Caja de panuelos | `Base.TissueBox` | 1.00 | 0.15 | — | Sin registro |
| Caja de abatelenguas | `Base.TongueDepressorBox` | 1.00 | 0.15 | — | Sin registro |
| Escoba de taza | `Base.ToiletBrush` | 0.60 | 0.20 | — | Sin registro |
| Paraguas (5 variantes) | `Base.UmbrellaBlack/Blue/Red/TINTED/White` | 1.50 | 0.60 | — | Sin registro |
| Tenazas de cocina / cucharon | `Base.KitchenTongs` / `Base.Ladle` | 0.60 | 0.15 | — | Sin registro |
| Cortador de pizza | `Base.PizzaCutter` | 0.50 | 0.12 | — | Sin registro |
| Espatula | `Base.Spatula` | 0.60 | 0.12 | — | Sin registro |
| Abrelatas | `Base.TinOpener` | 0.60 | 0.15 | — | Sin registro |
| Batidor | `Base.Whisk` | 0.60 | 0.10 | — | Sin registro |
| Rallador / colador | `Base.CheeseGrater` / `Base.Strainer` | 1.00 | 0.30 | — | Sin registro |

### Comparación de pesos solicitados que ya coinciden con el juego

Valores de Jill observados en la sesión del 29/10 con Weight Monitor 1.6.3. `REVISAR` indica que esa versión no tenía meta configurada; los valores observados sí coinciden con el peso base indicado. No son validación de las versiones nuevas.

| Nombre | ID técnico | Base / meta solicitada | Observado en monitor 1.6.3 | Estado |
|---|---|---:|---|---|
| Cuenco vacío | `Base.Bowl` | 0.50 kg | 0.50 kg (1; target=sin_meta; anterior a 1.6.9) | REVISAR |
| Caña de pescar | `Base.FishingRod` | 1.00 kg | 1.00 kg (1; target=sin_meta; anterior a 1.6.9) | REVISAR |
| Manguera de goma | `Base.RubberHose` | 0.30 kg | 0.30 kg (1; target=sin_meta; anterior a 1.6.9) | REVISAR |
| Trapo de cocina | `Base.DishCloth` | 0.20 kg | 0.20 kg/unidad (5; target=0.2) | OK |
| Tela esterilizada | `Base.AlcoholRippedSheets` | 0.10 kg | 0.10 kg/unidad (4; target=0.1) | OK |
| Destornillador | `Base.Screwdriver` | 0.10 kg | 0.10 kg (1; target=0.1) | OK |
| Bidon de gasolina, 10 L | `Base.PetrolCan` | 1.60 kg vacio; meta 1.60 kg + 0.75 kg/L | 1.60 kg (1; Jill 29/10, monitor 1.6.3; combustible no registrado; target=sin_meta) | REVISAR (lectura anterior a 1.6.9; combustible sin medir) |
### Criterio de peso para vidrio

| ID | Meta propuesta | Criterio y evidencia |
|---|---:|---|
| `Base.BrokenGlass` | 0.05 kg | Estimacion de un fragmento utilizable de 10 x 5 x 0.4 cm; a 2.5 g/cm3 son unos 50 g ([Guardian Glass](https://www.guardianglass.com/content/dam/guardianindustriesholdings/collateral/usca/brochure_expert_series_EN_doc5_mfg_process_float_glass_2020.pdf)). La definicion B42 original marca 0.50 kg. |
| `Base.GlassShiv` | 0.10 kg | Estimacion para una cuchilla improvisada: fragmento de vidrio mas un agarre envuelto. La receta usa 1 `Base.BrokenGlass` y una ligadura/herramienta ([receta B42](https://pzfans.com/en/wiki/recipes/Base/MakeGlassShiv/craftRecipe/)); la definicion original marca 0.50 kg. |

### Otros objetos y variantes agregados

Cada fila corresponde a un ID individual que el parche y el monitor registran por separado. `Base` es el peso definido originalmente en los scripts de Build 42 o del mod que aporta el objeto; `No definido` indica que no encontre una definicion con peso explicito. `Observado` y `Estado` solo cambian con evidencia de sesi?n.

| Secci?n | ID tecnico (un elemento por fila) | Base (kg) | Meta (kg) | Observado (kg) | Estado |
|---|---|---:|---:|---:|---|
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Appalachian_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Appalachian_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Cottontail_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Cottontail_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Dutch_V1_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Dutch_V1_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Dutch_V2_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Dutch_V2_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Dutch_V3_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Dutch_V3_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_EnglishSpot_V1_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_EnglishSpot_V1_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_EnglishSpot_V2_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_EnglishSpot_V2_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_EnglishSpot_V3_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_EnglishSpot_V3_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Harlequin_V1_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Harlequin_V1_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Harlequin_V2_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Harlequin_V2_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Harlequin_V3_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Harlequin_V3_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Swamp_Female_rabdoe` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Head_Rabbit_Swamp_Juvenile_rabkitten` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Appalachian_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Appalachian_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Appalachian_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Appalachian_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Appalachian_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Appalachian_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Cottontail_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Cottontail_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Cottontail_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Cottontail_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Cottontail_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Cottontail_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V1_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V1_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V1_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V1_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V1_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V1_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V2_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V2_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V2_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V2_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V2_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V2_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V3_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V3_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V3_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V3_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V3_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Dutch_V3_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V1_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V1_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V1_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V1_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V1_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V1_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V2_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V2_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V2_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V2_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V2_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V2_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V3_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V3_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V3_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V3_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V3_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_EnglishSpot_V3_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V1_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V1_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V1_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V1_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V1_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V1_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V2_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V2_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V2_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V2_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V2_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V2_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V3_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V3_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V3_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V3_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V3_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Harlequin_V3_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Swamp_Female_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Swamp_Female_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Swamp_Juvenile_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Swamp_Juvenile_Grey_Full` | 1.00 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Swamp_Male_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.AMR_Hide_Rabbit_Swamp_Male_Grey_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.Rabbit_Head_Appalachian` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.Rabbit_Head_CottonTail` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.Rabbit_Head_Swamp` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.Rabbit_Kitten_Head_Appalachian` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.Rabbit_Kitten_Head_CottonTail` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.Rabbit_Kitten_Head_Swamp` | 0.50 | 0.10 | ï¿½ | Sin registro |
| Pieles y cabezas de conejo | `Base.RabbitLeather_Full` | 1.00 | 0.25 | ï¿½ | Sin registro |
| Almohadas | `Base.Pillow` | 1.00 | 0.60 | 0.60 (1 unidades, 28/10) | OK |
| Almohadas | `Base.Pillow_Crafted` | 1.00 | 0.60 | — | Sin registro |
| Almohadas | `Base.Pillow_Happyface` | 1.00 | 0.60 | — | Sin registro |
| Almohadas | `Base.Pillow_Heart` | 1.00 | 0.60 | — | Sin registro |
| Almohadas | `Base.Pillow_Military` | No definido | 0.60 | — | Sin registro |
| Almohadas | `Base.Pillow_Star` | 1.00 | 0.60 | — | Sin registro |
| Bayas | `Base.BeautyBerry` | 0.10 | 0.05 | — | Sin registro |
| Bayas | `Base.BerryBlack` | 0.10 | 0.05 | — | Sin registro |
| Bayas | `Base.BerryBlue` | 0.10 | 0.05 | — | Sin registro |
| Bayas | `Base.BerryGeneric1` | 0.10 | 0.05 | — | Sin registro |
| Bayas venenosas | `Base.BerryGeneric2` | 0.10 | 0.05 | actual 0.0495; total 0.072 kg/2 (Jill 02/11, log 1.9.3; 03/11, monitor 1.9.7); 04/11: Visto, count=0, actual 0.0495, meta 0.05 (monitor 1.9.7) | Visto (04/11 sin instancia; la lectura anterior REVISAR sigue sin estado/fracción) |
| Bayas | `Base.BerryGeneric3` | 0.10 | 0.05 | — | Sin registro |
| Bayas | `Base.BerryGeneric4` | 0.10 | 0.05 | — | Sin registro |
| Bayas | `Base.BerryGeneric5` | 0.10 | 0.05 | — | Sin registro |
| Bayas | `Base.BerryPoisonIvy` | 0.10 | 0.03 | 0.03 (4 unidades, 28/10) | REVISAR |
| Bayas | `Base.HollyBerry` | 0.10 | 0.05 | — | Sin registro |
| Bayas | `Base.Rosehips` | 0.10 | 0.05 | — | Sin registro |
| Bayas | `Base.Strewberrie` | 0.10 | 0.05 | Jill 06/11, monitor 1.9.7: actual/total 0.023 kg/1, target 0.05, stackStatus=OK | REVISAR (sin estado/fracción) |
| Bayas | `Base.WinterBerry` | 0.10 | 0.05 | — | Sin registro |
| Botellas | `Base.BeerBottle` | 0.40 | 0.40 | 0.40 (1 unidades, 28/10) | OK |
| Botellas | `Base.HotWaterBottle` | 0.40 | 0.40 | — | Sin registro |
| Botellas | `Base.PopBottle` | 0.10 | 0.05 | 0.05 (2 unidades, 28/10) | OK |
| Botellas | `Base.PopBottleRare` | 0.10 | 0.05 | — | Sin registro |
| Botellas | `Base.WaterBottle` | 0.10 | 0.05 | — | Sin registro |
| Cerillos y encendedores | `Base.Lighter` | 0.10 | 0.02 | — | Sin registro |
| Cerillos y encendedores | `Base.LighterBBQ` | 0.30 | 0.05 | — | Sin registro |
| Cerillos y encendedores | `Base.LighterDisposable` | 0.10 | 0.02 | — | Sin registro |
| Cerillos y encendedores | `Base.Matches` | 0.10 | 0.03 | 0.03 (4 unidades, 28/10) | OK |
| Cinta, hilo y cordel | `Base.DuctTape` | 0.50 | 0.30 | 0.30 (1 unidades, 28/10) | OK |
| Cinta, hilo y cordel | `Base.Rope` | 0.80 | 0.50 | — | Sin registro |
| Cinta, hilo y cordel | `Base.RopeStack` | 8.00 | 0.80 | — | Sin registro |
| Cinta, hilo y cordel | `Base.String` | 0.20 | 0.05 | — | Sin registro |
| Cinta, hilo y cordel | `Base.Thread` | 0.10 | 0.05 | 0.05 (1 unidades, 28/10) | OK |
| Cinta, hilo y cordel | `Base.Thread_Aramid` | 0.20 | 0.05 | — | Sin registro |
| Cinta, hilo y cordel | `Base.Thread_Sinew` | 0.20 | 0.10 | 0.10 (3 unidades, 28/10) | OK |
| Cinta, hilo y cordel | `Base.Twine` | 0.50 | 0.05 | 0.05 (5 unidades, 28/10) | OK |
| Cocina y cubiertos | `Base.Fork` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.Fork_Bone` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.Fork_Gold` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.Fork_Silver` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.ForkForged` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.MortarPestle` | 0.80 | 0.80 | 0.80 (1 unidades, 28/10) | OK |
| Cocina y cubiertos | `Base.Pot` | 1.00 | 0.80 | — | Sin registro |
| Cocina y cubiertos | `Base.PotForged` | 1.00 | 0.80 | — | Sin registro |
| Cocina y cubiertos | `Base.Saucepan` | 0.70 | 0.50 | — | Sin registro |
| Cocina y cubiertos | `Base.SaucepanCopper` | 0.70 | 0.50 | — | Sin registro |
| Cocina y cubiertos | `Base.Spoon` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.Spoon_Bone` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.Spoon_Gold` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.Spoon_Silver` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.SpoonForged` | 0.25 | 0.03 | — | Sin registro |
| Cocina y cubiertos | `Base.WoodenSpoon` | 0.10 | 0.03 | 0.03 (1 unidades, 28/10) | OK |
| Cuchillos | `Base.BreadKnife` | 1.00 | 0.25 | — | Sin registro |
| Cuchillos | `Base.ButterKnife` | 0.25 | 0.03 | — | Sin registro |
| Cuchillos | `Base.ButterKnife_Gold` | 0.25 | 0.03 | — | Sin registro |
| Cuchillos | `Base.ButterKnife_Silver` | 0.25 | 0.03 | — | Sin registro |
| Cuchillos | `Base.HuntingKnife` | 1.00 | 0.25 | — | Sin registro |
| Cuchillos | `Base.HuntingKnifeForged` | 1.00 | 0.25 | — | Sin registro |
| Cuchillos | `Base.KitchenKnife` | 0.70 | 0.20 | 0.20 (3 unidades, 28/10) | OK |
| Cuchillos | `Base.KitchenKnifeForged` | 0.60 | 0.20 | — | Sin registro |
| Cuchillos | `Base.KnifeFillet` | 0.70 | 0.10 | 0.10 (2 unidades, 28/10) | OK |
| Cuchillos | `Base.KnifeShiv` | 0.50 | 0.15 | 0.15 (1 unidades, 28/10) | Visto |
| Cuchillos | `Base.SteakKnife` | 0.50 | 0.10 | — | Sin registro |
| Cuchillos | `UndeadSurvivor.PrepperKnifeKnock` | 0.30 | 0.20 | — | Sin registro |
| Cuchillos | `UndeadSurvivor.PrepperKnifeStab` | 0.30 | 0.20 | 0.20 (1 unidades, 28/10) | OK |
| Cuchillos | `UndeadSurvivor.PrepperKnifeSwing` | 0.30 | 0.20 | — | Sin registro |
| Desarmadores | `Base.Screwdriver` | 0.50 | 0.10 | 0.10 (8 unidades, 28/10) | OK |
| Desarmadores | `Base.Screwdriver_Improvised` | 0.50 | 0.10 | — | Sin registro |
| Desarmadores | `Base.Screwdriver_Old` | 0.50 | 0.10 | — | Sin registro |
| Frutas | `Base.Apple` | 0.20 | 0.15 | Jill 06/11, monitor 1.9.7: actual 0.0198–0.087; total 0.020–0.115 kg/1–2, target 0.15, stackStatus=OK | REVISAR (sin estado/fracción) |
| Frutas | `Base.Avocado` | 0.30 | 0.20 | 0.128 kg (1 unidad, log Jill 30/10; target=0.20) | REVISAR |
| Frutas | `Base.Banana` | 0.20 | 0.15 | — | Sin registro |
| Frutas | `Base.Cherry` | 0.10 | 0.05 | — | Sin registro |
| Frutas | `Base.Grapefruit` | 0.30 | 0.20 | 0.094–0.182 kg (1 unidad, log Jill 30/10; target=0.20) | REVISAR |
| Frutas | `Base.Grapes` | 0.20 | 0.15 | — | Sin registro |
| Limón silvestre | `Base.Lemon` | 0.20 | 0.15 | actual 0.0975; total 0.230 kg/2 (Jill 02/11, log 1.9.3; 03/11 y 04/11, monitor 1.9.7) | REVISAR (el monitor no registró estado ni fracción consumida) |
| Frutas | `Base.Mango` | 0.30 | 0.20 | — | Sin registro |
| Frutas | `Base.Orange` | 0.20 | 0.15 | — | Sin registro |
| Frutas | `Base.Peach` | 0.20 | 0.15 | — | Sin registro |
| Frutas | `Base.Pear` | 0.20 | 0.15 | — | Sin registro |
| Frutas | `Base.Pineapple` | 0.30 | 0.25 | — | Sin registro |
| Frutas | `Base.Watermelon` | 3.00 | 3.00 | — | Sin registro |
| Frutas | `Base.WatermelonSliced` | 0.30 | 0.30 | 0.117 kg (1–6 unidades, log Jill 30/10; target=0.30) | REVISAR |
| Frutas | `Base.WatermelonSmashed` | 0.60 | 0.60 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeBucket` | 1.50 | 0.80 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeCrudeChisel` | 1.30 | 0.60 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeFleshingTool` | 1.50 | 0.60 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeGardenSaw` | 1.00 | 0.60 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeHacksaw` | 1.00 | 0.75 | 0.75 (1 unidades, 28/10) | OK |
| Herramientas caseras | `HomemadeThings.HomemadeKnittingNeedles` | 0.40 | 0.10 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeNeedle` | 0.05 | 0.05 | 0.05 (1 unidades, 28/10) | OK |
| Herramientas caseras | `HomemadeThings.HomemadePickaxe` | 3.00 | 2.00 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeShovel` | 2.50 | 1.50 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeSieve` | 2.00 | 1.00 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeSieve_Frame` | 1.50 | 0.80 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeSieve_Mesh` | 0.50 | 0.20 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeSledgehammer` | 10.00 | 3.00 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeTrowel` | 1.00 | 0.50 | — | Sin registro |
| Herramientas caseras | `HomemadeThings.HomemadeWoodenMallet` | 1.50 | 0.60 | 0.60 (1 unidades, 28/10) | OK |
| Herramientas pequenas | `Base.Scissors` | 0.50 | 0.10 | 0.10 (1 unidades, 28/10) | OK |
| Herramientas pequenas | `Base.ScissorsForged` | 0.50 | 0.10 | — | Sin registro |
| Herramientas pequenas | `Base.Stake` | 0.50 | 0.25 | 0.25 (1 unidades, 28/10) | Visto |
| Herramientas pequenas | `Base.TinOpener_Old` | 0.60 | 0.15 | 0.15 (1 unidades, 28/10) | OK |
| Herramientas pequenas | `Base.Whetstone` | 0.50 | 0.20 | 0.20 (1 unidades, 28/10) | OK |
| Herramientas pequenas | `HomemadeThings.HomemadeScissors` | 0.70 | 0.20 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.Comfrey` | 0.10 | 0.05 | 0.05 (5 unidades, 28/10) | OK |
| Hierbas y plantas silvestres | `Base.ComfreyDried` | 0.10 | 0.03 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.CommonMallow` | 0.10 | 0.05 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.CommonMallowDried` | 0.10 | 0.03 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.Dandelions` | 0.10 | 0.05 | 0.015–0.031 kg (1–5 unidades, log Jill 30/10; target=0.05) | REVISAR |
| Hierbas y plantas silvestres | `Base.GrapeLeaves` | 0.10 | 0.05 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.LemonGrass` | 0.10 | 0.05 | 0.05 (2 unidades, 28/10) | OK |
| Hierbas y plantas silvestres | `Base.MintHerb` | 0.10 | 0.05 | 0.05 (3 unidades, 28/10) | OK |
| Hierbas y plantas silvestres | `Base.MintHerbDried` | 0.10 | 0.03 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.Plantain` | 0.10 | 0.05 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.PlantainDried` | 0.10 | 0.03 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.WildGarlic2` | 0.10 | 0.05 | — | Sin registro |
| Hierbas y plantas silvestres | `Base.WildGarlicDried` | 0.10 | 0.03 | — | Sin registro |
| Martillos y pinzas | `Base.BallPeenHammer` | 1.50 | 0.45 | — | Sin registro |
| Martillos y pinzas | `Base.BallPeenHammerForged` | 1.50 | 0.45 | — | Sin registro |
| Martillos y pinzas | `Base.Hammer` | 1.50 | 0.70 | — | Sin registro |
| Martillos y pinzas | `Base.HammerForged` | 1.50 | 0.70 | — | Sin registro |
| Martillos y pinzas | `Base.HammerStone` | 2.00 | 1.00 | — | Sin registro |
| Martillos y pinzas | `Base.Pliers` | 0.30 | 0.15 | 0.15 (1 unidades, 28/10) | OK |
| Sacos de dormir | `Base.SleepingBag_BluePlaid_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_Camo_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_Cheap_Black_Packed` | No definido | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_Cheap_Blue_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_Cheap_Green` | 5.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_Cheap_Green2_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_Cheap_Green_Packed` | 3.00 | 2.00 | 2.00 (1 unidades, 28/10) | OK |
| Sacos de dormir | `Base.SleepingBag_Green_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_GreenPlaid_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_Hide_Packed` | 4.00 | 3.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_HighQuality_Brown_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_RedPlaid_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sacos de dormir | `Base.SleepingBag_Spiffo_Packed` | 3.00 | 2.00 | — | Sin registro |
| Sal, pimienta y saleros | `Base.CrushedPepper` | 0.10 | 0.05 | 0.05 (6 unidades, 28/10) | OK |
| Sal, pimienta y saleros | `Base.CrushedSalt` | 0.10 | 0.05 | — | Sin registro |
| Sal, pimienta y saleros | `Base.Pepper` | 0.20 | 0.08 | Jill 07/11 20:04, monitor 1.9.7: actual 0.071 kg, total 0.151 kg/2; target 0.08 kg. Jill 04/11: actual 0.071/0.068; totales 0.151/0.148 kg/2 y 0.071 kg/1; intervalo previo 0.053–0.074 kg (30/10) | REVISAR (sin estado ni fracción consumida) |
| Sal, pimienta y saleros | `Base.Peppercorn` | 0.10 | 0.036 | Jill 07/11 17:24, monitor 1.9.7: actual 0.0054, total 0.005 kg/1, target 0.036 kg; luego Visto. Jill 06/11: actual 0.00864, total 0.034 kg/3; lecturas anteriores 0.00432–0.03492 kg (30/10) | REVISAR (sin estado/fracción) |
| Sal, pimienta y saleros | `Base.PepperHabanero` | 0.10 | 0.15 | — | Sin registro |
| Sal, pimienta y saleros | `Base.PepperHabaneroDried` | 0.10 | 0.05 | — | Sin registro |
| Sal, pimienta y saleros | `Base.PepperJalapeno` | 0.10 | 0.15 | Jill 06/11, monitor 1.9.7: actual/total 0.075 kg/1, target 0.15, stackStatus=OK | REVISAR (sin estado/fracción) |
| Sal, pimienta y saleros | `Base.PepperJalapenoDried` | 0.10 | 0.05 | — | Sin registro |
| Sal, pimienta y saleros | `Base.PepperShaker_Box` | 4.00 | 4.00 | — | Sin registro |
| Sal, pimienta y saleros | `Base.Salt` | 0.20 | 0.10 | Jill 07/11 20:04, monitor 1.9.7: actual/total 0.090 kg/1; target 0.10 kg. Jill 04/11: actual/total 0.085 y 0.080 kg/1; intervalo previo 0.055–0.10 kg (30/10) | REVISAR (sin estado ni fracción consumida) |
| Sal, pimienta y saleros | `Base.SaltRock` | 0.20 | 0.15 | — | Sin registro |
| Sal, pimienta y saleros | `Base.SaltShaker_Box` | 4.00 | 4.00 | — | Sin registro |
| Sal, pimienta y saleros | `Base.SeasoningSalt` | 0.20 | 0.10 | — | Sin registro |
| Sal, pimienta y saleros | `Base.ShakerEmpty` | 0.10 | 0.05 | — | Sin registro |
| Sal, pimienta y saleros | `Base.ShakerEmpty_Box` | 4.00 | 4.00 | — | Sin registro |
| Trapos | `Base.AlcoholRippedSheets` | 0.10 | 0.10 | 0.10 (4 unidades, 28/10) | OK |
| Trapos | `Base.DishCloth` | 0.30 | 0.20 | 0.20 (5 unidades, 28/10) | OK |
| Trapos | `Base.RippedSheets` | 0.10 | 0.05 | — | Sin registro |
| Trapos | `Base.RippedSheetsBundle` | 1.00 | 0.80 | — | Sin registro |
| Trapos | `Base.RippedSheetsDirty` | 0.10 | 0.05 | 0.05 (1 unidades, 28/10) | OK |
| Trapos | `Base.RippedSheetsDirtyBundle` | 1.00 | 0.80 | — | Sin registro |
| Trapos | `Base.RippedSheetsSterilizedBundle` | 1.00 | 0.80 | — | Sin registro |

| Marcador visual de amputacion (pie izq.) | `TOC.Amputation_Foot_L` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (pie der.) | `TOC.Amputation_Foot_R` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (antebrazo izq.) | `TOC.Amputation_ForeArm_L` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (antebrazo der.) | `TOC.Amputation_ForeArm_R` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (mano izq.) | `TOC.Amputation_Hand_L` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (mano der.) | `TOC.Amputation_Hand_R` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (pantorrilla izq.) | `TOC.Amputation_LowerLeg_L` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (pantorrilla der.) | `TOC.Amputation_LowerLeg_R` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (brazo izq.) | `TOC.Amputation_UpperArm_L` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (brazo der.) | `TOC.Amputation_UpperArm_R` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (muslo izq.) | `TOC.Amputation_UpperLeg_L` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |
| Marcador visual de amputacion (muslo der.) | `TOC.Amputation_UpperLeg_R` | 0.00 | 0.00 (marcador no transportable) | Sin registro | Sin registro |

En los scripts activos no existe un objeto individual llamado `SaltShaker` o `PepperShaker`: `ShakerEmpty` es el salero vacio, y `Salt`/`Pepper` son los contenidos separados. Los objetos `*_Box` de LTP son cajas de varios productos, por eso conservan 4 kg. `DishClothWet` conserva su peso para no borrar la diferencia por humedad. Las metas son objetivos del parche y deben validarse en Jill. Los 12 IDs `TOC.Amputation_*` anteriores tienen `hidden=true`, `ItemType=clothing` y `BodyLocation`: son marcadores de apariencia equipados en el personaje, no partes del cuerpo llevables en inventario. Su peso 0 kg es correcto para su funcion y Weight Monitor 1.7.2 los marca `BASE_OK` solo si la definicion sigue en 0.

## Registro y verificacion a cargo de Codex

### Modelo de rendimiento animal

| Parámetro | Regla aplicada |
|---|---|
| Peso de referencia | Promedio de `minWeight` y `maxWeight` en `AnimalDefinitions`; si faltan, usa una estimación prudente por el nombre del tipo y 25 kg como último recurso. |
| Tope base de piezas | `ceil(0.5 × sqrt(peso medio en kg))`. El crecimiento por raíz cuadrada favorece animales grandes sin multiplicar cortes en proporción lineal al peso. |
| Habilidad | `skillBonus = floor(Carnicería / 5)`. Se suma a ambos extremos del rango: `min = max(1, floor(base × 0.55) + bonus)`; `max = base + bonus`. El número final se sortea inclusive. |
| Carne | El presupuesto total se comparte entre las piezas de comida del animal; máximo técnico de 30. La nutrición por pieza conserva el cálculo original del juego. |
| Huesos | Usa el mismo rango por tamaño y habilidad, máximo técnico 24; si la definición tiene cráneo, reserva una pieza. El resto se distribuye entre IDs según el promedio de `minNb` y `maxNb` de sus definiciones. |
| Microfauna | Si el peso medio es menor de 1 kg, obtiene como máximo una pieza de comida y cero huesos. |
| Modos | El presupuesto reemplaza la multiplicación vanilla por tamaño, piso/gancho y nivel que elevaba el total sin un límite común. Se aplica en `ButcheringUtil.addAnimalPart` a vanilla y a mods que usen ese flujo, incluidos UndeadWildlife y Animal Remaster. |

| Ejemplo de especie | Peso medio de referencia | Carnicería 0: carne/huesos | Carnicería 5: carne/huesos | Carnicería 10: carne/huesos |
|---|---:|---:|---:|---:|
| Ratón | 0.10 kg | 1 / 0 | 1 / 0 | 1 / 0 |
| Gallina adulta | 3.50 kg | 1 / 1 | 1–2 / 1–2 | 2–3 / 2–3 |
| Conejo adulto | 4.50 kg | 1–2 / 1–2 | 2–3 / 2–3 | 3–4 / 3–4 |
| Cordero | 45 kg | 2–4 / 2–4 | 3–5 / 3–5 | 4–6 / 4–6 |
| Oveja adulta | 90 kg | 2–5 / 2–5 | 3–6 / 3–6 | 4–7 / 4–7 |
| Venada cola blanca | 155 kg | 3–7 / 3–7 | 4–8 / 4–8 | 5–9 / 5–9 |
| Vaca adulta | 655 kg | 7–13 / 7–13 | 8–14 / 8–14 | 9–15 / 9–15 |

Los intervalos son topes totales por animal; el cráneo cuenta dentro del tope de huesos. Los ejemplos usan los pesos medios vanilla; una especie de mod con datos de peso propios escala con esos datos. La validación runtime aún está pendiente.

### Auditoria de stack

`ChilaSeda_InventoryTetrisSizeCap_B42` 1.2.1 fija en 100 el limite de stack que Inventory Tetris usa para las definiciones consultadas. El log de Jill del 29/10 con Weight Monitor 1.6.1 completo el catalogo (`checked=10803`, `ok=10803`, `revisar=0`) y registro stack 100/`OK` para vidrio roto, cuchilla de vidrio y huesos. La correccion local del monitor 1.6.2 evita consultar el nombre personalizado de contenedores cercanos sin padre; Weight Monitor 1.6.3 añade las metas de vidrio, 1.6.4 sincroniza la meta dinamica del garrafon, 1.6.5 agrega metas para katana rota, vara de madera y hueso normal, 1.6.6 sincroniza el peso dinamico de AlcoholWipes; 1.6.7 agrega Base.BlackSage; 1.6.9 sincroniza gasolina y revisa metas de huesos y AlcoholWipes; la sesión 1.6.3 lo registró con el nombre “Salvia mellifera (Silvestre)” y peso 0.10 kg.

| Nombre | ID técnico | Límite Tetris objetivo | Límite observado en la sesión disponible | Estado |
|---|---|---:|---|---|
| Vidrio roto | `Base.BrokenGlass` | 100 | 100, stackStatus=OK (log Jill 29/10) | OK |
| Cuchilla de vidrio | `Base.GlassShiv` | 100 | 100, stackStatus=OK (log Jill 29/10) | OK |
| Hueso de animal | `Base.AnimalBone` | 100 | 100, stackStatus=OK (log Jill 29/10) | OK |
| Hueso grande de animal | `Base.LargeAnimalBone` | 100 | 100, stackStatus=OK (log Jill 29/10) | OK |
| Hueso pequeño | `Base.SmallAnimalBone` | 100 | 100, stackStatus=OK (log Jill 29/10) | OK |
| Fragmento de hueso afilado | `Base.SharpBoneFragment` | 100 | Sin registro de límite en el log disponible | Sin registro |

Weight Monitor 1.6.5 escanea automaticamente cada 120 ticks de juego (cada 30 mientras el panel esta abierto). Actualiza las listas de contenedores cercanos antes del escaneo y registra todos los tipos accesibles. Si un contenedor cercano no tiene objeto padre, usa su tipo como nombre y omite `getCustomName()`, que en B42 causa `NullPointerException` en ese estado. `SCAN_STATUS OK` solo se escribe si se refrescan ambas paginas y se recorren los contenedores; ante fallo registra `SCAN_STATUS BLOCKED reason=...` y no marca objetos como `Visto`. Para `Base.CorpseAnimal`, separa registros por especie y calcula la meta con el 16% del punto medio de peso vivo (24.80 kg para doe cola blanca).

Weight Monitor 1.6.5 crea un archivo UTF-8 por sesion en `Zomboid/mods/PesosLogs/WeightMonitor_<fecha>_<id>.txt` mediante el puente Java compilado contra ZombieBuddy 2.3.4. Cada cambio registra tipo, nombre, peso unitario, peso combinado, meta, cantidad, limites Tetris/script, estado y origen; separa ubicaciones y tipos de animal. Registra `Visto` cuando un objeto deja de estar accesible, conserva eventos pendientes si falla la escritura y deja el panel **Ctrl + Shift + F7** como vista opcional.

Codex revisa las entradas nuevas del log despues de cada sesion de Jill, compara resultados con los objetivos y actualiza las columnas `Observado` y `Estado` de las tablas. Si no hay una medicion del tipo en la sesion actual, queda `Sin registro`; no se pide a Chila que haga la prueba manual.

| Estado | Significado |
|---|---|
| **OK** | El peso observado coincide con el objetivo, con tolerancia de 0.005 kg. |
| **REVISAR** | El peso observado difiere del objetivo del parche, o el tipo aun no tiene una meta configurada (`sin_meta`). |
| **Visto** | Se registro antes en esta sesion, pero ya no aparece en las ubicaciones accesibles (inventario, mochilas y contenedores cercanos). |
| **Sin registro** | No hay medicion actual para ese tipo; es una anotacion de la tabla, no una etiqueta del monitor. |

Cada archivo corresponde a una sesion y comienza con `SESSION_START`; el cierre normal registra `SESSION_END` y `SESSION_CLOSED`. Si Jill se cierra directamente, su archivo conserva los registros escritos hasta ese momento y el siguiente inicio crea un archivo nuevo.

## Sesión más reciente

| Sesión local | Log | Registros de objetos | Estado |
|---|---|---|---|
| 2026-11-08 17:58:24–23:11:14 -06:00 (sin cierre) | WeightMonitor_2026-11-08_17-58-24_84ffb2cc.txt | 16,721 estados en 555 IDs; 1,492 `OK`, 7,301 `REVISAR` y 7,928 `Visto`. No hay `SESSION_END`; el último registro es 23:11:14. | Se agregaron metas de machetes y se diagnosticó el alcance de la bellota cercana; parche 2.1.1 y monitor 1.9.8 listos para validar en Jill. |

### Lecturas actuales para IDs con meta del manual

| ID técnico | Estado | Actual (kg/unidad) | Total (kg) | Meta (kg) | Cantidad | Último registro local |
|---|---|---:|---:|---:|---:|---|
| `Base.Acorn` | Visto | 0.069 | 0.63 | 0.0057 | 0 | 2026-11-08 23:11:14 -06:00 |
| `Base.AlcoholWipes` | Visto | 0.06 | 0.12 | 0.06 | 0 | 2026-11-07 19:37:30 -06:00 |
| `Base.AnimalBone` | Visto | 0.175 | 0.175 | 0.175 | 0 | 2026-11-07 19:55:58 -06:00 |
| `Base.Bandaid` | Visto | 0.001 | 0.013 | 0.001 | 0 | 2026-11-07 18:51:36 -06:00 |
| `Base.Battery` | Visto | 0.023 | 0.023 | 0.023 | 0 | 2026-11-07 17:26:16 -06:00 |
| `Base.BeerBottle` | Visto | 0.4 | 0.4 | 0.4 | 0 | 2026-11-07 19:36:57 -06:00 |
| `Base.BlackSage` | Visto | 0.05 | 0.9 | 0.05 | 0 | 2026-11-07 19:27:33 -06:00 |
| `Base.BluePen` | Visto | 0.006 | 0.006 | 0.006 | 0 | 2026-11-07 19:37:37 -06:00 |
| `Base.Bowl` | Visto | 0.5 | 0.5 | 0.5 | 0 | 2026-11-07 20:04:23 -06:00 |
| `Base.BreadKnife` | Sin registro | — | — | 0.25 | — | — |
| `Base.Machete` | Visto | 2.0 | 4.0 | 0.71 | 0 | 2026-11-08 21:41:23 -06:00 |
| `Base.MacheteBlade_NoTang` | Visto | 2.0 | 2.0 | 0.48 | 0 | 2026-11-08 18:27:10 -06:00 |
| `Base.Machete_Crude` | Sin registro | — | — | 0.71 | — | — |
| `Base.BrokenGlass` | Visto | 0.05 | 0.85 | 0.05 | 0 | 2026-11-07 19:46:32 -06:00 |
| `Base.ButterKnife` | Visto | 0.03 | 0.03 | 0.03 | 0 | 2026-11-07 17:49:01 -06:00 |
| `Base.CarKey` | Visto | 0 | 0.36 | 0.012 | 0 | 2026-11-07 19:37:19 -06:00 |
| `Base.Comfrey` | OK | 0.05 | 0.4 | 0.05 | 8 | 2026-11-07 17:17:08 -06:00 |
| `Base.CommonMallow` | Sin registro | — | — | 0.05 | — | — |
| `Base.CrushedPepper` | OK | 0.05 | 0.2 | 0.05 | 4 | 2026-11-07 17:17:08 -06:00 |
| `Base.CrushedSalt` | Visto | 0.05 | 0.4 | 0.05 | 0 | 2026-11-07 19:20:05 -06:00 |
| `Base.DishCloth` | OK | 0.2 | 0.8 | 0.2 | 4 | 2026-11-07 17:17:08 -06:00 |
| `Base.DuctTape` | Visto | 0.3 | 0.3 | 0.3 | 0 | 2026-11-07 19:14:43 -06:00 |
| `Base.FishingRod` | OK | 1 | 1 | 1 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.Fork` | Visto | 0.03 | 0.03 | 0.03 | 0 | 2026-11-07 19:47:12 -06:00 |
| `Base.GlassShiv` | Visto | 0.1 | 0.1 | 0.1 | 0 | 2026-11-07 19:32:43 -06:00 |
| `Base.HammerForged` | OK | 0.7 | 0.7 | 0.7 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.HandTorch` | Visto | 0.2 | 0.2 | 0.2 | 0 | 2026-11-07 19:27:36 -06:00 |
| `Base.Katana_Broken` | OK | 0.7 | 0.7 | 0.7 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.Key1` | OK | 0.009 | 0.063 | 0.009 | 7 | 2026-11-07 17:17:08 -06:00 |
| `Base.KitchenKnife` | Visto | 0.2 | 0.2 | 0.2 | 0 | 2026-11-07 19:27:33 -06:00 |
| `Base.KnifeFillet` | OK | 0.1 | 0.1 | 0.1 | 1 | 2026-11-07 19:54:52 -06:00 |
| `Base.LargeAnimalBone` | Visto | 0.7 | 0.7 | 0.7 | 0 | 2026-11-07 19:27:33 -06:00 |
| `Base.LemonGrass` | Visto | 0.05 | 0.3 | 0.05 | 0 | 2026-11-07 19:27:33 -06:00 |
| `Base.LighterDisposable` | OK | 0.02 | 0.04 | 0.02 | 2 | 2026-11-07 17:17:08 -06:00 |
| `Base.Mango` | Sin registro | — | — | 0.2 | — | — |
| `Base.Matches` | Visto | 0.03 | 0.21 | 0.03 | 0 | 2026-11-07 19:49:00 -06:00 |
| `Base.MortarPestle` | OK | 0.8 | 0.8 | 0.8 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.Newspaper_Recent` | Visto | 0.13 | 0.13 | 0.13 | 0 | 2026-11-07 19:27:33 -06:00 |
| `Base.Peach` | Sin registro | — | — | 0.15 | — | — |
| `Base.Pencil` | Visto | 0.005 | 0.005 | 0.005 | 0 | 2026-11-07 19:44:03 -06:00 |
| `Base.Pepper` | Visto | 0.071 | 0.151 | 0.08 | 0 | 2026-11-07 20:04:51 -06:00 |
| `Base.Peppercorn` | Visto | 0.0054 | 0.005 | 0.036 | 0 | 2026-11-07 17:24:35 -06:00 |
| `Base.PetrolCan` | OK | 1.6 | 1.6 | 1.6 | 1 | 2026-11-07 20:02:13 -06:00 |
| `Base.Pillow` | Visto | 0.6 | 0.6 | 0.6 | 0 | 2026-11-07 18:41:35 -06:00 |
| `Base.Plantain` | Visto | 0.05 | 0.2 | 0.05 | 0 | 2026-11-07 19:27:33 -06:00 |
| `Base.Pliers` | Visto | 0.15 | 0.15 | 0.15 | 0 | 2026-11-07 18:33:34 -06:00 |
| `Base.PopBottle` | Visto | 0.05 | 0.1 | 0.05 | 0 | 2026-11-07 18:44:03 -06:00 |
| `Base.Pot` | Visto | 0.8 | 0.8 | 0.8 | 0 | 2026-11-07 17:24:33 -06:00 |
| `Base.RedPen` | Visto | 0.006 | 0.006 | 0.006 | 0 | 2026-11-07 19:37:37 -06:00 |
| `Base.RippedSheetsDirty` | Sin registro | — | — | 0.05 | — | — |
| `Base.Rope` | Visto | 0.5 | 0.5 | 0.5 | 0 | 2026-11-07 19:46:58 -06:00 |
| `Base.RubberHose` | OK | 0.3 | 0.3 | 0.3 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.Salt` | Visto | 0.09 | 0.09 | 0.1 | 0 | 2026-11-07 20:04:51 -06:00 |
| `Base.Saucepan` | Visto | 0.5 | 0.5 | 0.5 | 0 | 2026-11-07 18:12:49 -06:00 |
| `Base.Scissors` | Visto | 0.1 | 0.1 | 0.1 | 0 | 2026-11-07 19:47:12 -06:00 |
| `Base.Screwdriver` | Visto | 0.1 | 0.5 | 0.1 | 0 | 2026-11-07 19:56:28 -06:00 |
| `Base.SleepingBag_Cheap_Green` | Sin registro | — | — | 2 | — | — |
| `Base.SleepingBag_Cheap_Green_Packed` | OK | 2 | 2 | 2 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.Spoon` | OK | 0.03 | 0.03 | 0.03 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.Thread_Sinew` | Visto | 0.1 | 0.1 | 0.1 | 0 | 2026-11-07 17:53:24 -06:00 |
| `Base.TinOpener` | OK | 0.15 | 0.15 | 0.15 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.TinOpener_Old` | OK | 0.15 | 0.15 | 0.15 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.Twine` | Visto | 0.05 | 0.05 | 0.05 | 0 | 2026-11-07 19:14:54 -06:00 |
| `Base.Whetstone` | OK | 0.2 | 0.2 | 0.2 | 1 | 2026-11-07 17:17:08 -06:00 |
| `Base.WoodenStick2` | Visto | 0.4 | 0.4 | 0.4 | 0 | 2026-11-07 19:47:12 -06:00 |
| `Base.WristWatch_Left_DigitalDress` | OK | 0.021 | 0.021 | 0.021 | 1 | 2026-11-07 17:17:08 -06:00 |

### Lecturas REVISAR sin meta observadas en la sesión más reciente

Los rangos siguientes son metas para revisar pesos variables; el monitor acepta límites por objeto, informa el rango y marca `OK` solo si todas las lecturas individuales quedan dentro. USDA da 106 g por 2/3 de taza para una ensalada de verduras ([MyPlate](https://myplate-stg.kwaps.platform.usda.gov/recipes/rainbow-veggie-salad)) y 120–135 g por taza de coleslaw ([ARS](https://www.ars.usda.gov/ARSUserFiles/80400530/pdf/portion.pdf)); una ensalada de 1.04 kg equivale a unas 8 tazas, una porción muy grande, y no a una porción común. El guiso de res con verduras de USDA pesa 252 g por taza ([ARS](https://www.ars.usda.gov/ARSUserFiles/80400530/pdf/8586/csfii85_4days_codebook.pdf)): 5 kg son cerca de 20 tazas antes de contar la olla, posible como una tanda grande, excesivo como plato individual. El log conserva `target=sin_meta` por compatibilidad y añade `targetRange=min..max`.

| ID técnico | Lectura observada | Rango/meta propuesta | Estado |
|---|---|---|---|
| `Base.DeadRatSkinned` | 0.07375 kg actual; 0.191 kg/2 en inventario. La sesión mostró ejemplares entre 0.07375 y 0.13529 kg. Última lectura local 2026-11-07 20:04:51 -06:00. | 0.05–0.15 kg por ejemplar; la variación observada cabe en el rango. | Propuesta; `target=sin_meta` |
| `Base.Salad` | 0.62–1.04 kg por objeto observado; última lectura 1.04 kg, 2.70 kg/3. Los tres objetos suman el total, no una ensalada individual. Última lectura local 2026-11-07 20:04:59 -06:00. | 0.15–1.10 kg según ingredientes; 1.04 kg es una ensalada excepcionalmente grande, no 2 kg. | Propuesta; `target=sin_meta` |
| `Base.PotOfStew` | Una olla `Estofado de Hierbas`: 3.81 kg; el script B42 fija 3.0 kg y el tag permite dividirla en tazones. `MaxItems=6` de la receta cuenta ingredientes, no porciones. Última lectura local 2026-11-07 19:51:04 -06:00. | 3.0–5.0 kg para una olla completa según receta/carga; 5 kg es una tanda grande (≈20 tazas), no un plato individual. | Propuesta; `target=sin_meta` |

## Cálculo del peso de las banderas

Como referencia, una bandera estándar de 3 × 5 pies tiene un área aproximada de 1.39 m². Una tela ligera de poliéster para banderas de 110 g/m² pesa cerca de 153 g; por eso se eligió **0.15 kg** para las banderas y estandartes de DGVFlags, sin contar un asta. Es una estimación basada en una bandera estándar, ya que el mod no especifica dimensiones físicas ni materiales.

Referencias: [catálogo de tela M FLAGS, 110 g/m²](https://www.mflags.com/img/CATALOGUE.pdf) · [bandera comercial de 3 × 5 pies, 5 oz](https://www.faire.com/product/p_d6r8s3gwqd).

## Parches y validación

- `ChilaSeda_Fix_Any_Wall_Posters_3D_Weight_B42_3818605173`: fija los pósters DGVPosters en 0.05 kg.
- `ChilaSeda_Fix_Any_Wall_Flags_3D_Weight_B42_3818605688`: fija banderas y estandartes DGVFlags en 0.15 kg.
- `ChilaSeda_Fix_True_Weight_VanillaWeights_B42_3768669395` 1.4.0: aplica objetivos Base/mod y actualiza instancias accesibles; para esqueletos `Base.CorpseAnimal` calcula 16% del punto medio del peso vivo de la especie y resuelve el animal por API, modData, traducción o nombre visible.
- `ChilaSeda_AnimalBalance_B42` 2.1.0: limita rendimientos por masa y Carnicería, comparte un tope total de huesos entre extracción y cráneo, y manda los productos al contenedor seleccionado o al piso. Reúne también la protección para no cargar animales/cadáveres de más de 50 kg y los fixes de carnicería, ataques y Halo de Undead Wildlife. Esos ajustes se activan solo cuando Undead Wildlife está presente y no es una dependencia requerida.
- `ChilaSeda_Fix_Project_Zomboid_AutoTools_B42_Vanilla` 1.0.1: restaura el objeto que estaba en la mano y devuelve a su contenedor el cuchillo equipado automáticamente al despiezar animales desde el piso o al iniciar el despiece de un cadáver guardado en el inventario.
- `ChilaSeda_InventoryTetrisSizeCap_B42` 1.2.1: fuerza `maxStackSize=100` para toda definición que Inventory Tetris calcula o consulta, incluidos objetos vanilla, de mods, únicos y contenedores; conserva las dimensiones de rejilla de contenedores.
- `ChilaSeda_Audit_WeightMonitor_B42` 1.6.9: registra peso, cantidad, limites Tetris/script y estado de stack; calcula la meta de esqueletos con la formula del 16% compartida con VanillaWeightFix y audita el catalogo y comparte las metas dinamicas del garrafon y AlcoholWipes con VanillaWeightFix, ademas de Base.BlackSage. Omite `getCustomName()` si un contenedor cercano no tiene padre.

Versiones locales vigentes para esta tabla: VanillaWeightFix 1.4.10 y Audit Suite 2.1.1. La sesión más reciente registrada por Weight Monitor 1.9.7 es la del 2026-11-06 incluida arriba; sus estados actuales no incluyen el estado/fracción de consumo de alimentos.

Los nombres de objetos Base corresponden a la localización ES-MX del juego. DGVFlags y DGVPosters no incluyen traducciones propias, así que sus nombres visibles permanecen en inglés. La tabla contiene los valores objetivo del código; la confirmación dentro del juego sigue pendiente.

















## Apéndice: objetos auxiliares con peso base cero

El peso cero es correcto para estas entradas porque son overlays invisibles o adjuntos sintéticos que representan estado visual o funcional y no tienen existencia física independiente. La fuente define `hidden=true`, `WorldRender=false` y una ubicación corporal para los overlays; Extended Vanilla Weapons los documenta como `Fake attachments` con `Tags=NoRemoveAttachment` y aplica el efecto de masa del estado mediante `WeightModifier`; The Only Cure documenta `PistolVisual` como copia del arma real para mostrarla en la prótesis; Hunter Expansion documenta `YakPhoneLight` como objeto temporal, no obtenible, creado al activar la linterna y destruido al apagarla. Weight Monitor 1.7.5 compara cada peso cargado contra 0.00 y escribe `BASE_OK` o `REVIEW_MISMATCH`. Estas entradas no son objetos físicos para asignarles una masa de catálogo.

| Grupo | ID técnico | Base (kg) | Meta revisada (kg) | Observado (kg) | Estado |
|---|---|---:|---:|---:|---|
| Overlay de vendaje vanilla | `Base.Bandage_Abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Abdomen_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Chest_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Groin_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Head_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftFoot` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftFoot_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftHand` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftHand_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftLowerArm` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftLowerArm_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftLowerLeg` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftLowerLeg_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftUpperArm` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftUpperArm_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftUpperLeg` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_LeftUpperLeg_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_Neck_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightFoot` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightFoot_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightHand` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightHand_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightLowerArm` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightLowerArm_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightLowerLeg` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightLowerLeg_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightUpperArm` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightUpperArm_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightUpperLeg` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de vendaje vanilla | `Base.Bandage_RightUpperLeg_Blood` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Abdomen_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Abdomen_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Abdomen_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Abdomen_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Abdomen_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Abdomen_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Chest_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Chest_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Chest_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Chest_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Chest_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Chest_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Groin_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Groin_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Groin_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Groin_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Groin_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Groin_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LForearm_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LForearm_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LForearm_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LForearm_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LForearm_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LForearm_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LHand_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LHand_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LHand_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LHand_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LHand_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LHand_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LUArm_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LUArm_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LUArm_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LUArm_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LUArm_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_LUArm_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Neck_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Neck_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Neck_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Neck_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Neck_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_Neck_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RForearm_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RForearm_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RForearm_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RForearm_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RForearm_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RForearm_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RHand_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RHand_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RHand_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RHand_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RHand_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RHand_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RUArm_Bite_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RUArm_Bite_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RUArm_Laceration_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RUArm_Laceration_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RUArm_Scratch_Female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay de herida vanilla | `Base.Wound_RUArm_Scratch_Male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Luz auxiliar temporal de Hunter Expansion | `HunterExpansion.YakPhoneLight` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Copia visual sin masa de The Only Cure | `TOC.PistolVisual` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination308NoClip_1` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_0` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_1` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_10` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_11` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_12` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_13` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_14` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_15` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_16` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_17` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_18` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_19` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_2` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_20` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_21` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_22` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_23` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_24` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_25` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_26` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_27` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_28` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_29` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_3` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_30` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_31` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_4` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_5` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_6` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_7` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_8` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16Magazine_9` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.Combination556M16NoClip_1` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.CombinationM500ShotgunShellNoClip_1` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.CombinationM500ShotgunShellNoClip_2` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.CombinationM500ShotgunShellNoClip_3` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.CombinationM500ShotgunShellNoClip_4` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Adjunto sintético de estado de arma | `VFECombination.CombinationShotgunShellNoClip_1` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_abrasion_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_avulsion_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bandage_torn_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_bruised_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_abdomen_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_abdomen_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_chest_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_chest_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_foot_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_foot_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_foot_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_foot_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_groin_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_groin_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_hand_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_hand_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_hand_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_hand_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_head_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_head_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_lowerarm_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_lowerarm_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_lowerarm_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_lowerarm_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_lowerleg_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_lowerleg_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_lowerleg_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_lowerleg_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_neck_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_neck_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_upperarm_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_upperarm_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_upperarm_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_upperarm_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_upperleg_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_upperleg_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_upperleg_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_compression_upperleg_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_concussion_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_debris_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dirty_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dislocation_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dislocation_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dislocation_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dislocation_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dislocation_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_dislocation_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_mild_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_moderate_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_frostbite_severe_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_inflamed_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_iodine_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_maggots_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_necrotic_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_over_bandaged_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_poorly_stitched_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_puncture_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_reopened_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_rinsed_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_bite_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_burn_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_scar_deep_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sling_upperarm_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sling_upperarm_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sling_upperarm_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sling_upperarm_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_foot_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_foot_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_foot_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_foot_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_hand_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_hand_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_hand_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_hand_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_lowerarm_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_lowerarm_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_lowerarm_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_lowerarm_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_lowerleg_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_lowerleg_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_lowerleg_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_sprain_lowerleg_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_abdomen` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_chest` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_foot_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_foot_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_groin` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_hand_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_hand_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_head` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_lowerarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_lowerarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_lowerleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_lowerleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_neck` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_upperarm_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_upperarm_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_upperleg_left` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_swollen_upperleg_right` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_tourniquet_upperarm_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_tourniquet_upperarm_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_tourniquet_upperarm_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_tourniquet_upperarm_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_tourniquet_upperleg_left_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_tourniquet_upperleg_left_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_tourniquet_upperleg_right_female` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |
| Overlay corporal WoundExpansion | `WoundExpansion.WE_Skin_tourniquet_upperleg_right_male` | 0.00 | 0.00 | — | BASE_OK de definición; sin lectura runtime |

### Pieles de cerdito (Animal Remaster)

Se asignan metas a 60 pieles de cerdito, 15 variantes por cuatro estados: `Full`/`Fur` verdes 3.75 kg, `Fur_Tan_Wet` 3.60 kg y `Fur_Tan` secas 1.50 kg. B42 define `piglet` entre 15 y 110 kg; se usa el punto medio (62.5 kg) y el rendimiento de piel porcina aproximado de 6% del peso vivo de University of Maine Cooperative Extension: 3.75 kg. La etapa húmeda conserva 96% (pérdida del 4%, dentro del rango porcino publicado de 2–4%); el cuero seco usa 40% del verde, coherente con las pérdidas de curtido documentadas para otras pieles. Es una extrapolación a etapa animal, no pesaje individual. Los cortes `Small` de cerdito quedan pendientes por falta de área/tamaño definido. VanillaWeightFix 1.4.19 y Weight Monitor 1.9.3 sincronizan las 60 metas.

Referencias: `B42: media/lua/shared/Definitions/animal/PigDefinitions.lua` (15–110 kg para piglet); [University of Maine Cooperative Extension, Understanding Pork Yields](https://extension.umaine.edu/publications/1073e/) (la piel es aproximadamente 6% del peso vivo); [Weight and area of leather](https://eopcw.com/find/downloadFiles/159) (55–65% de pérdida al secar). Pendiente lectura runtime posterior a estas versiones.
### Ajuste de pieles húmedas adultas de conejo

VanillaWeightFix 1.4.20 y Weight Monitor 1.9.4 añaden meta de 0.384 kg a 48 pieles adultas `Fur_Tan_Wet`. El cálculo usa como base el peso seco de 0.225 kg, con 31.76% de humedad en cuero semiterminado de conejo (World Rabbit Science 2016); la materia seca estimada es 0.1535 kg. Para wet-blue uso 60% de humedad, dentro del rango técnico 40–60% que publica UNIDO: 0.1535 / 0.40 = 0.384 kg. El mismo estudio reporta 64.36% de humedad en piel natural, consistente con 0.43 kg verdes y aproximadamente 0.153 kg de materia seca. Son mediciones de grupos distintos y el cálculo supone materia seca constante; sirve como meta realista aproximada. Las 24 pieles húmedas juveniles siguen sin meta por falta de una masa de pelt por edad.

Referencias: [Souza et al., Compositional analysis and physicochemical and mechanical testing of tanned rabbit skins](https://polipapers.upv.es/index.php/wrs/article/view/4037) (31.76% de humedad tras acabado; 64.36% in natura); [UNIDO, Classification of Wet-Blue Hides by Quality](https://www.unido.org/publications/ot/9656569/pdf) (40–60% de humedad en wet-blue); [FAO, The Rabbit](https://www.fao.org/4/t1690e/t1690e.pdf) (las pieles de conejo se conservan secándolas). Pendiente de lectura runtime posterior.
### Pieles juveniles de conejo

Se asignan metas a 96 IDs juveniles: 0.30 kg verde (`Full`/`Fur`), 0.27 kg wet-tanned y 0.16 kg seco curtido; 24 IDs por etapa. Una revisión de datos de faena resume 299 g de pelt a ocho semanas y 383 g a doce semanas (Ockerman, 1967). Se usa el valor de ocho semanas como el mejor análogo publicado para “Juvenile”; FAO indica que el manto infantil madura alrededor de nueve semanas. Como masa verde adulta se usa 0.43 kg, el húmedo y el seco escalan por los cocientes adultos 0.384/0.43 y 0.225/0.43: 0.299×0.893=0.267 kg y 0.299×0.523=0.156 kg, redondeados a 0.27 y 0.16. Se sustituye la meta previa de 0.10 kg para 24 `Full`, que no estaba respaldada. La edad concreta de cada objeto juvenil del mod no se indica; por tanto, estas metas son estimaciones por análogo de ocho semanas, no pesajes por raza o individuo. VanillaWeightFix 1.4.21 y Weight Monitor 1.9.5 sincronizan las 96 etapas.

Referencias: [revisión de pesos de pelt por edad, Ockerman 1967](https://krishikosh.egranth.ac.in/server/api/core/bitstreams/7009c658-278b-4f8e-aaaf-8cd7148f7906/content) (299 g a 8 semanas; 383 g a 12); [FAO, producción de piel de conejo](https://www.fao.org/4/x5082e/X5082E0h.htm) (manto infantil maduro alrededor de 9 semanas; tamaño del pelt depende de superficie corporal). Pendiente lectura runtime posterior.


---

### 🔗 Otros enlaces de interés

- [🏠 Inicio del repositorio](../README.md)
- [🤝 Cómo contribuir](../CONTRIBUTING.md)
- [🚀 Releases de mods](releases/README.md)
