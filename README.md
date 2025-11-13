# Airflow Rock

## Monolithic repository for Airflow Rocks.

Rocks for Apache Airflow.
This repository hosts all the necessary files to build Rocks for various Airflow components.
To interact with this repository, use `just` to run commands.

## Developing Apache Airflow Rock

This document further explains how to build, customize, and work with the **Apache Airflow Rock** defined in `rockcraft.yaml`.
It is intended for people interested in creating their own version of the rock.

---

## Overview

This rock builds **Apache Airflow** from source on **Ubuntu** and packages it as a Pebble-managed OCI container.
It includes a wide range of official Airflow providers and runs Airflow in standalone mode by default.

**Key features:**

* Builds Airflow directly from the upstream GitHub tag (e.g. `3.1.0`).
* Uses the official constraints file for Python 3.12 to ensure dependency compatibility.
* Stages common Airflow provider packages.
* Runs the Airflow webserver and scheduler automatically via Pebble on startup.
* Includes licensing information for both Airflow and this rock.


## Project Structure

```
airflow-rocks/
├─ 3.1.0/
│  ├─ rockcraft.yaml         # Rockcraft manifest defining the rock
│  └─ DEVELOPING.md          # (this file)
├─ environment               # (optional) global env vars if used
```

## Building the rock

To build the rock:

```bash
cd airflow-rocks/3.1.0
rockcraft pack
```

This will:

* Fetch Airflow source from GitHub (`3.1.0` tag)
* Build Airflow and providers into a Python environment
* Package it as an OCI image wrapped in a `.rock` file (e.g., `airflow-rock_3.1.0_amd64.rock`)

## Running and testing the rock

Once built, you can run the rock locally using `docker`:

### Using Docker

```bash
# Load the rock into your local Docker daemon
rockcraft.skopeo --insecure-policy copy oci-archive:airflow-rock_3.1.0_amd64.rock docker-daemon:airflow-rock:3.1.0
# Run the rock
docker run -it --rm -p 5000:5000 airflow-rock:3.1.0
```

The container will start Airflow in standalone mode.
The Airflow web UI will be available at: http://localhost:5000

### Using Pebble inside the container

```bash
docker exec -it <container_id> pebble services
docker exec -it <container_id> pebble logs
```

## Rock services and checks

The rock defines one service, managed by Pebble:

```yaml
services:
  airflow:
    startup: enabled
    command: /usr/bin/airflow standalone
```

This runs Airflow’s built-in standalone mode, which launches:

* A webserver (API-Server)
* A scheduler
* A metadata database (SQLite, by default)

A simple liveness check verifies Airflow is running:

```yaml
checks:
  airflow-running:
    exec:
      command: pgrep airflow
```

## Parts Explained

The rock is built from several parts:

| Part                       | Purpose                                                                 |
| -------------------------- | ----------------------------------------------------------------------- |
| **airflow**                | Builds Apache Airflow from source and installs providers                |
| **airflow-license**        | Includes upstream Apache Airflow LICENSE                                |
| **airflow-rock-license**   | Includes the LICENSE for this rock                                      |
| **env_stage** *(optional)* | Stages a system-wide `/etc/environment` file with environment variables |

### Python constraints

The build uses Airflow’s official constraints file for a certain version of Python, for example:

```yaml
python-constraints:
  - https://raw.githubusercontent.com/apache/airflow/constraints-3.1.0/constraints-3.12.txt
```

This ensures the pinned versions of all dependencies and providers match Airflow 3.1.0.

## Environment variables

The `env_stage` part stages a `/etc/environment` file. This can set global variables like:

```bash
AIRFLOW_HOME=/var/lib/airflow
PYTHONPATH="/usr/lib/python3:$PYTHONPATH"
```

However, Airflow has sensible defaults, so this part is **optional**.
If you do not include it, Airflow will default to:

* `AIRFLOW_HOME=$HOME/airflow` (e.g., `/root/airflow`)
* Standard Python search paths


## Provider packages

The rock installs a comprehensive list of Airflow providers, including:

* Amazon (`apache-airflow-providers-amazon`)
* Google (`apache-airflow-providers-google`)
* Kubernetes (`apache-airflow-providers-cncf-kubernetes`)
* PostgreSQL, MySQL, ODBC, Redis, etc.

To customize providers, edit the `python-packages` list in the `airflow` part.
### List providers installed
```bash
airflow providers list
```

## Licensing

Two license files are included in the rock image:

* `licenses/LICENSE-airflow` – Apache 2.0 license for upstream Airflow
* `licenses/LICENSE-airflow-rock` – License for this rock’s source


## Development tips

* Use `rockcraft pack --verbosity debug` for more detailed logs during builds.
* Use `rockcraft clean` if builds fail due to stale state.
* If you change the Python version, update the constraints URL accordingly.

Please refer to the [DEVELOPING.md](./DEVELOPING.md) guide for details on developing, building, and testing the Airflow Rocks in this repository.