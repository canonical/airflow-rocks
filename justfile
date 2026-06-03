set export
set fallback


[private]
default:
	just --list

[private]
start-local-registry:
	docker start registry || docker run -d -p 5000:5000 --name registry registry:2

[private]
stop-local-registry:
	docker stop registry && docker rm registry

[private]
push-to-local-registry VERSION:
	#!/usr/bin/env bash
	set -euxo pipefail

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"
	arch="$(dpkg --print-architecture)"

	rockcraft.skopeo --insecure-policy copy --dest-tls-verify=false \
	  "oci-archive:${VERSION}/airflow_${rock_version}_${arch}.rock" \
	  "docker://localhost:5000/airflow-rock-dev:${rock_version}"

pack VERSION DEBUG="":
	#!/usr/bin/env bash
	set -euxo pipefail

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	cd "${VERSION}" && rockcraft pack ${DEBUG}

clean VERSION:
	cd "${VERSION}" && rockcraft clean
	cd "${VERSION}" && rm -f *.rock

run VERSION: (pack VERSION) (start-local-registry) (push-to-local-registry VERSION)
	#!/usr/bin/env bash
	set -euxo pipefail
	trap 'just stop-local-registry' EXIT

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:5000/airflow-rock-dev:${rock_version}" | jq -r .Digest)"
	IMAGE_REF="localhost:5000/airflow-rock-dev@${DIGEST}"
	cd "${VERSION}" && \
	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss edit -i "${IMAGE_REF}"

test VERSION: (pack VERSION) (start-local-registry) (push-to-local-registry VERSION)
	#!/usr/bin/env bash
	set -euxo pipefail
	trap 'just stop-local-registry' EXIT

	rock_version="$(cat $VERSION/rockcraft.yaml | yq '.version')"

	DIGEST="$(rockcraft.skopeo --insecure-policy inspect --tls-verify=false "docker://localhost:5000/airflow-rock-dev:${rock_version}" | jq -r .Digest)"
	IMAGE_REF="localhost:5000/airflow-rock-dev@${DIGEST}"
	cd "${VERSION}" && \
	env GOSS_KUBECTL_BIN="$(which kubectl)" GOSS_OPTS="--color" GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss run -i "${IMAGE_REF}"
