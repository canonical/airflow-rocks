set export
set fallback


[private]
default:
	just --list

[private]
start-local-registry:
	docker run -d -p 5000:5000 --name registry registry:2

[private]
stop-local-registry:
	docker stop registry && docker rm registry

[private]
push-to-local-registry version:
	#!/usr/bin/env bash
	set -euo pipefail

	rockcraft.skopeo --insecure-policy copy --dest-tls-verify=false \
	  "oci-archive:{{version}}/airflow-rock_{{version}}_amd64.rock" \
	  "docker://localhost:5000/airflow-rock-dev:{{version}}"

pack version debug="":
	cd "{{version}}" && rockcraft pack {{debug}}

clean version:
	cd "{{version}}" && rockcraft clean
	cd "{{version}}" && rm -f *.rock

run version: (pack version) (start-local-registry) (push-to-local-registry version)
	#!/usr/bin/env bash
	set -euo pipefail
	trap 'just stop-local-registry' EXIT

	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:5000/airflow-rock-dev:{{version}}" | jq -r .Digest)"
	IMAGE_REF="localhost:5000/airflow-rock-dev@${DIGEST}"

	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss edit -i "${IMAGE_REF}"   -e AIRFLOW__CORE__LOAD_EXAMPLES=false

test version: (pack version) (start-local-registry) (push-to-local-registry version) 
	#!/usr/bin/env bash
	set -euo pipefail
	trap 'just stop-local-registry' EXIT

	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:5000/airflow-rock-dev:{{version}}" | jq -r .Digest)"
	IMAGE_REF="localhost:5000/airflow-rock-dev@${DIGEST}"

	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss run -i "${IMAGE_REF}"   -e AIRFLOW__CORE__LOAD_EXAMPLES=true