# Developing Airflow Rocks

This document describes how to build, test, and validate the Apache Airflow Rocks packaged in this repository.

---
## Installing dependencies

The following are dependencies to be able to develop and test changes to the Temporal rocks:

- a K8s distribution (ideally k8s by Canonical)
- rockcraft
- yq
- kubectl
- just
- docker
- goss
- kgoss

There are convenient snaps for all of the above dependencies besides goss and kgoss. The recommended way to install these until a goss snap is released would be:
```bash
goss_base_url="https://github.com/goss-org/goss/releases/latest/download"
curl -L ${goss_base_url}/goss-linux-amd64 -o /usr/local/bin/goss
chmod +rx /usr/local/bin/goss
curl -L ${goss_base_url}/kgoss -o /usr/local/bin/kgoss
chmod +rx /usr/local/bin/kgoss
```


## Repository Structure

```bash
.
├── 3.1.0
│   ├── goss_wait.yaml
│   ├── goss.yaml
│   └── rockcraft.yaml
├── DEVELOPING.md
├── justfile
├── LICENSE
└── README.md
```

- Each version directory contains everything needed to build that Airflow release.
- Currently, this repository supports **Apache Airflow 3.1.0**, the latest stable upstream version.

---

## Building the Rock

To build the Airflow Rock:

```bash
cd 3.1.0
rockcraft pack
```

This produces a .rock artifact (e.g., airflow-rock_<version>_amd64.rock) in the same directory.

## Using the Justfile

The justfile provides shortcuts for common developer actions.

`just pack <version>`	Build the .rock for the current version
`just clean <version>`	Remove build artifacts and reset workspace
`just test <version>`	Run validation and health checks (goss tests)
`just run <version>`	Launch a test pod to inspect and interact with the built image

### Example usage

```bash
just pack <version>
just run <version>
```

The run command starts a containerized Airflow instance for local smoke testing and validation.

### Testing and Validation

- goss.yaml and goss_wait.yaml define validation checks that ensure:
- Airflow starts and runs as expected within the Rock.
- All required providers and dependencies are present.
- Environment variables are correctly staged and loaded.

### To execute the tests
```bash
just test <version>
```

## Versioning

Each Airflow version maintains its own isolated build definition:
- Future versions will follow the same structure.
- Shared components such as the justfile remain at the repository root.

## License

This project is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)
