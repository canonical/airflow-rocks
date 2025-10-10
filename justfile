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
push-to-local-registry VERSION:
	#!/usr/bin/env bash
	set -euxo pipefail

	rockcraft.skopeo --insecure-policy copy --dest-tls-verify=false \
	  "oci-archive:${VERSION}/airflow-rock_${VERSION}_amd64.rock" \
	  "docker://localhost:5000/airflow-rock-dev:${VERSION}"

pack VERSION DEBUG="":
	#!/usr/bin/env bash
	set -euxo pipefail

	cd "${VERSION}" && rockcraft pack ${DEBUG}

clean VERSION:
	#!/usr/bin/env bash
	set -euxo pipefail
	
	cd "${VERSION}" && rockcraft clean
	cd "${VERSION}" && rm -f *.rock

run VERSION: (pack VERSION) (start-local-registry) (push-to-local-registry VERSION)
	#!/usr/bin/env bash
	set -euxo pipefail
	trap 'just stop-local-registry' EXIT

	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:5000/airflow-rock-dev:${VERSION}" | jq -r .Digest)"
	IMAGE_REF="localhost:5000/airflow-rock-dev@${DIGEST}"

	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss edit -i "${IMAGE_REF}"  

test VERSION: (pack VERSION) (start-local-registry) (push-to-local-registry VERSION) 
	#!/usr/bin/env bash
	set -euxo pipefail
	trap 'just stop-local-registry' EXIT

	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:5000/airflow-rock-dev:${VERSION}" | jq -r .Digest)"
	IMAGE_REF="localhost:5000/airflow-rock-dev@${DIGEST}"

	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss run -i "${IMAGE_REF}"
