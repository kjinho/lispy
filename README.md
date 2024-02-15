# Lispy Image

To build the image:

```
podman build --build-arg ALPINE_VERSION=edge --build-arg DUCKDB_VERSION=0.10.0 -t lispy .
```

To run:
```
podman run -it --rm -v $(pwd):/work lispy -d /work/
```

Recommended alias:

```
alias lem='podman run -it --rm -v $(pwd):/work lispy -d /work/'
```