# airflow-rock

Canonical-packaged rock for Apache Airflow, designed for multi-service charm integration.

This repository defines a single, reproducible `.rock` containing all core Airflow components. It is intended to be reused across multiple charms, each orchestrating a specific Airflow service.

## Included Components

| Component         | Description                                  |
|------------------|----------------------------------------------|
| `airflow webserver` | Flask-based UI for DAG visualization         |
| `airflow scheduler` | DAG trigger engine and task dispatcher       |
| `airflow worker`    | Task executor (Celery/Kubernetes)            |
| `airflow triggerer` | Deferrable operator handler (optional)       |
| `airflow cli`       | Admin commands and DAG management            |


## Build Instructions

```bash
rockcraft pack
