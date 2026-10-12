# Compile with a saved JSON response

`--data` supplies a local JSON snapshot to existing Flutter constructors. The
compiler evaluates the original widget bodies; configuration explicitly maps
response fields to supported model inputs. It does not execute `fromJson`,
repositories, authentication, providers or asynchronous application startup.

Run this synthetic example from the repository root:

```sh
dart run bin/flutter_dom.dart build --project examples/data_snapshot \
  --data examples/data_snapshot/sample.json --dom-only \
  --output build/data-snapshot
python3 -m http.server 8120 --bind 127.0.0.1 --directory build/data-snapshot
```

The installed CLI accepts the same `--data` flag with `flutter_dom build web`.
Data and output paths are relative to your working directory; config and source
paths are relative to the selected project. Default source is `lib/main.dart`.

## Explicit bindings

In `flutter_dom.json`, `{"data":"/data/title"}` selects a value using JSON
Pointer. An empty pointer selects the entire current value. Escape `/` in a key
as `~1`, and `~` as `~0`; array indexes use `/0`, `/1`, etc.

Use `each` to project a selected array into supported original models:

```json
{
  "data": "/data/activities",
  "each": {
    "model": "lib/models.dart::Activity",
    "arguments": {
      "name": {"data": "/name"},
      "minutes": {"data": "/minutes"}
    }
  }
}
```

Pointers inside `each` are relative to each array item. Model references resolve
normally in the selected source/import graph; use `--resolve-imports` for
multi-file projects. `each` accepts an explicit model, named arguments and/or
positional arguments. It cannot inject widget implementations or call factories.
Raw JSON objects become literal compiler map inputs, even when their keys look
like compiler descriptors. Constructor types are still checked by the compiler.

Missing fields and invalid pointers fail explicitly. There are no inferred
defaults, field renaming, string-to-number conversions or automatic date parsing.
Supply the constructor's supported types rather than assuming the behavior of a
model's JSON factory. The CLI limits input files to 5 MiB; binding has a shared
20,000-step and 32-level limit, followed by normal compiler input limits.

Preview pages display **Supplied JSON data**. Reports record the source kind and
binding count, without the input file path or payload values. The generated HTML
contains selected data. This is a read-only snapshot taken at build time, not a
live backend connection or reactive state integration.

See [component previews](COMPONENT_PREVIEWS.md) for theme snapshots, composition
and supported constructor inputs. Keep application-specific configurations and
exports outside the compiler's tracked source tree.
