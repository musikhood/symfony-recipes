# Musikhood Symfony Flex recipes

Endpoint Symfony Flex hostujący recipes dla paczek Symfony utrzymywanych
przez Musikhood.

"Recipe" to mały zestaw kroków, które Symfony Flex wykonuje automatycznie
przy instalacji paczki: rejestracja bundla w `config/bundles.php`,
skopiowanie domyślnych szablonów do `config/packages/`, dopisanie zmiennych
środowiskowych do `.env`, wyświetlenie post-install message z
manualnymi krokami, których recipe nie powinien robić sam.

## Recipes hostowane tutaj

| Paczka | Wersje |
|---|---|
| [`musikhood/auth-client-bundle`](https://github.com/musikhood/auth-client-bundle) | `0.1` |

## Instalacja w aplikacji konsumenta

Dodaj endpoint do `composer.json` aplikacji, która ma korzystać z recipes
(jednorazowo):

```json
{
    "extra": {
        "symfony": {
            "endpoint": [
                "https://api.github.com/repos/musikhood/symfony-recipes/contents/index.json",
                "flex://defaults"
            ]
        }
    }
}
```

Linijka `flex://defaults` zostawia oficjalne recipes Symfony aktywnymi —
nie wywalaj jej. Kolejność ma znaczenie: Flex próbuje endpointów od lewej
do prawej i bierze pierwszy match.

Po dodaniu endpointu każde `composer require musikhood/<paczka>` automatycznie
pociągnie recipe. `composer remove` cofnie zmiany.

Pierwsze `composer require` po dodaniu endpointu zapyta:

```
Do you want to execute this recipe?
[y] Yes  [n] No  [a] Yes for all packages...
[p] Yes permanently, store this answer in composer.json
```

Wybierz **`p`** — Flex zapamięta zaufanie do tego endpointu w
`composer.json`, kolejne instalacje nie będą pytać.

## Struktura repo

```
.
├── index.json                                        # zbudowane — lista recipes/wersji
├── <vendor>.<package>.<version>.json                 # zbudowane — jeden plik na recipe-wersję
├── build.sh                                          # generator JSON z folderów
└── <vendor>/<package>/<version>/                     # źródło — to edytujesz
    ├── manifest.json                                 # bundles, copy-from-recipe, env, etc.
    └── config/                                       # szablony kopiowane do konsumenta
        └── ...
```

Folder `<vendor>/<package>/<version>/` jest **źródłem prawdy** — edytujesz
tylko tutaj. Konsument Flex pobiera `*.json` z roota, regenerowane z
folderu przez `build.sh`.

## Dodawanie / aktualizacja recipe

1. Stwórz lub zedytuj `<vendor>/<package>/<version>/manifest.json` plus
   szablony plików.
2. Uruchom `./build.sh`.
3. Zacommituj zarówno źródła jak i wygenerowane `*.json`.
4. Zrób push na `main`. Konsumenci widzą nowe recipe przy następnym
   `composer require` / `composer recipes:update`.

## Reference manifestu

Najczęściej używane klucze (pełna referencja:
[Symfony Flex docs](https://github.com/symfony/flex/blob/2.x/src/Configurator/)):

| Klucz | Efekt |
|---|---|
| `bundles` | Dodaje wpisy do `config/bundles.php`. |
| `copy-from-recipe` | Kopiuje szablony plików do konsumenta (`%CONFIG_DIR%/`, `%PUBLIC_DIR%/`, `%SRC_DIR%/`). |
| `env` | Dopisuje pary klucz=wartość do `.env` (nie nadpisuje istniejących). |
| `gitignore` | Dopisuje wpisy do `.gitignore`. |
| `post-install-output` | Linijki wyświetlane po `composer require` — wspiera tagi `<comment>`, `<fg=color>`, `<href=...>`. |
| `composer-scripts` | Dodaje wpisy do `scripts` w composer.json konsumenta. |
