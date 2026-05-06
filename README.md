# Musikhood Symfony Flex recipes

Symfony Flex endpoint hosting recipes for Musikhood-maintained Symfony bundles.

A "recipe" is the small set of automated steps Flex runs when a consumer
installs a bundle: registering the bundle in `config/bundles.php`, copying
default config templates into `config/packages/`, appending env vars to
`.env`, and printing post-install instructions for anything that has to be
done by hand.

## Recipes hosted here

| Package | Versions |
|---|---|
| [`musikhood/auth-client-bundle`](https://github.com/musikhood/auth-client-bundle) | `0.1` |

## Using these recipes from a consuming app

Add this endpoint to the consuming app's `composer.json` (one-time setup):

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

The `flex://defaults` line keeps the official Symfony recipes working — keep
it. The order matters: Flex tries endpoints left-to-right and uses the first
match.

After that, every `composer require musikhood/<bundle>` triggers the matching
recipe automatically. `composer remove` reverses it.

## Repo layout

```
.
├── index.json                                        # built — lists all recipes/versions
├── <vendor>.<package>.<version>.json                 # built — one per recipe-version
├── build.sh                                          # regenerates the built JSON
└── <vendor>/<package>/<version>/                     # source — what humans edit
    ├── manifest.json                                 # bundles, copy-from-recipe, env, etc.
    └── config/                                       # templates copied into the consumer
        └── ...
```

The folder under `<vendor>/<package>/<version>/` is the **source of truth** —
edit here. Flex consumers fetch the `*.json` files at the root, which are
regenerated from the source by `build.sh`.

## Adding or updating a recipe

1. Create or edit `<vendor>/<package>/<version>/manifest.json` and the
   accompanying template files.
2. Run `./build.sh`.
3. Commit both the source and the regenerated `*.json` artifacts.
4. Push to `main`. Consumers see the new recipe on their next `composer
   require` / `composer recipes:update`.

## Manifest reference

Most useful manifest keys (full reference: [Symfony Flex docs](https://github.com/symfony/flex/blob/2.x/src/Configurator/)):

| Key | Effect |
|---|---|
| `bundles` | Adds entries to `config/bundles.php`. |
| `copy-from-recipe` | Copies template files into the consumer (`%CONFIG_DIR%/`, `%PUBLIC_DIR%/`, `%SRC_DIR%/`). |
| `env` | Appends key=value lines to `.env` (won't overwrite existing keys). |
| `gitignore` | Appends entries to `.gitignore`. |
| `post-install-output` | Lines printed after `composer require` — supports `<comment>`, `<fg=color>`, `<href=...>` formatting. |
| `composer-scripts` | Adds entries to the consumer's composer.json `scripts` section. |
