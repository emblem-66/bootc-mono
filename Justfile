set shell := ["bash", "-uc"]

build image tag containerfile:
    set -euo pipefail
    podman build --file {{containerfile}} --tag {{image}}:{{tag}} .

rechunk image tag owner:
    set -euo pipefail
    IMAGE="{{image}}:{{tag}}"
    export CHUNKAH_CONFIG_STR=$(podman inspect "${IMAGE}")
    podman run --rm \
      --mount=type=image,src="${IMAGE}",target=/chunkah \
      -e CHUNKAH_CONFIG_STR \
      quay.io/coreos/chunkah:latest build \
        --compressed --max-layers 128 \
        --prune /sysroot/ --prune /ostree \
        --label ostree.commit- --label ostree.final-diffid- \
        --tag "${IMAGE}" \
    | podman load
    podman tag localhost/{{image}}:{{tag}} ghcr.io/{{owner}}/{{image}}:{{tag}}

push image tag owner actor:
    set -euo pipefail
    podman push --creds={{actor}}:${GITHUB_TOKEN} ghcr.io/{{owner}}/{{image}}:{{tag}}

sign image tag owner digest:
    set -euo pipefail
    cosign sign --yes ghcr.io/{{owner}}/{{image}}@{{digest}}


- run: just build "${{ inputs.image-name }}" "${{ inputs.tag }}" "${{ inputs.containerfile }}"
- run: just rechunk "${{ inputs.image-name }}" "${{ inputs.tag }}" "${{ github.repository_owner }}"
  if: ${{ inputs.rechunk }}
- run: just push "${{ inputs.image-name }}" "${{ inputs.tag }}" "${{ github.repository_owner }}" "${{ github.actor }}"
  if: ${{ inputs.push }}
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
