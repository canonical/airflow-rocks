set export
set fallback


# [private]
default:
	just --list

# [private]
start-local-registry:
	echo "Using MicroK8s registry at localhost:32000"; 
	
# [private]
stop-local-registry:
	@true 

# [private]
load-rock version:
	docker import {{version}}/airflow-rock_{{version}}_amd64.rock airflow-rock-dev:{{version}}; 

# [private]
push-to-local-registry version: (load-rock version)
	#!/usr/bin/env bash
	set -euo pipefail

	REGISTRY_HOST="localhost:32000"            # MicroK8s registry
	ROCK="{{version}}/airflow-rock_{{version}}_amd64.rock"

	SKOPEO="$(command -v rockcraft.skopeo || command -v skopeo)"
	[ -n "${SKOPEO}" ] || { echo "skopeo not found"; exit 1; }

	echo "Pushing ${ROCK} → docker://${REGISTRY_HOST}/airflow-rock-dev:{{version}}"
	"${SKOPEO}" --insecure-policy copy --dest-tls-verify=false \
	  "oci-archive:${ROCK}" \
	  "docker://${REGISTRY_HOST}/airflow-rock-dev:{{version}}"

pack version debug="":
	cd "{{version}}" && rockcraft pack {{debug}}

clean version:
	cd "{{version}}" && rockcraft clean
	cd "{{version}}" && rm -f *.rock

run version: (start-local-registry) (pack version) (push-to-local-registry version)
	#!/usr/bin/env bash
	set -euo pipefail

	REGISTRY_HOST="localhost:32000"
	IMG="airflow-rock-dev:{{version}}"

	SKOPEO="$(command -v rockcraft.skopeo || command -v skopeo)"
	[ -n "${SKOPEO}" ] || { echo "skopeo not found"; exit 1; }
	command -v jq >/dev/null || { echo "jq not found"; exit 1; }

	DIGEST="$("${SKOPEO}" --insecure-policy inspect --tls-verify=false \
	  "docker://${REGISTRY_HOST}/${IMG}" | jq -r .Digest)"
	[ -n "$DIGEST" ] || { echo "Failed to resolve digest"; exit 1; }
	IMAGE_REF="${REGISTRY_HOST}/airflow-rock-dev@${DIGEST}"

	KUBECTL_BIN="$(command -v kubectl || command -v microk8s.kubectl)"
	[ -n "${KUBECTL_BIN}" ] || { echo "kubectl not found"; exit 1; }

	env GOSS_KUBECTL_BIN="${KUBECTL_BIN}" \
	    GOSS_OPTS="--color" \
	    GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss run -i "${IMAGE_REF}"





test version: (start-local-registry) (pack version) (push-to-local-registry version)
	#!/usr/bin/env bash
	set -euo pipefail

	REGISTRY_HOST="localhost:32000"
	IMG_NAME="airflow-rock-dev"
	VER="{{version}}"

	SKOPEO="$(command -v rockcraft.skopeo || command -v skopeo)"
	[ -n "$SKOPEO" ] || { echo "skopeo not found"; exit 1; }
	command -v jq >/dev/null || { echo "jq not found"; exit 1; }

	DIGEST="$("$SKOPEO" --insecure-policy inspect --tls-verify=false \
	  "docker://${REGISTRY_HOST}/${IMG_NAME}:${VER}" | jq -r .Digest)"
	[ -n "$DIGEST" ] || { echo "Failed to resolve digest"; exit 1; }
	IMAGE_REF="${REGISTRY_HOST}/${IMG_NAME}@${DIGEST}"

	KUBECTL_BIN="$(command -v kubectl || command -v microk8s.kubectl)"
	[ -n "${KUBECTL_BIN}" ] || { echo "kubectl not found"; exit 1; }

	env \
		GOSS_KUBECTL_BIN="${KUBECTL_BIN}" \
		GOSS_OPTS="--color" \
		GOSS_WAIT_OPTS="-r 480s -s 2s" \
	kgoss run \
		-i "${IMAGE_REF}" \
		-e AIRFLOW_HOME=/var/lib/airflow \
		-e AIRFLOW__CORE__LOAD_EXAMPLES=false \
		-e AIRFLOW__WEBSERVER__WEB_SERVER_HOST=0.0.0.0 \
		-c '/bin/sh -lc "install -d -m 0777 \"$AIRFLOW_HOME\"; airflow standalone"'
