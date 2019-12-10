{{- $data := (datasource "package-list") -}}
{{- $packages := $data.packages -}}
{{- $layers := $data.layers -}}
{{- $revision := $data.productrevision -}}
{{- define "cache-key"}}{{template "cache-version"}}-{{.}}{{end -}}
{{- define "cache-version"}}test8-v1{{end -}}
# Any change to cache-version invalidates all build layer and package caches.
# Current cache version: {{template "cache-version"}}

executors:
  releaser:
    docker:
      - image: circleci/buildpack-deps
    environment:
      PRODUCT_REVISION: "{{if $revision}}{{$revision}}{{end}}"
      AUTO_INSTALL_TOOLS: 'YES'
    shell: /usr/bin/env bash -euo pipefail -c

workflows:
  build-release:
    jobs:
      - cache-builder-images:
          filters:
            branches:
              only:
                - /build-.*/
                - /ci.*/
      {{- range $packages}}
      - {{.meta.BUILD_JOB_NAME}}: { requires: [ cache-builder-images ] }{{end}}
      - bundle-releases:
          requires:
            {{- range $packages}}
            - {{.meta.BUILD_JOB_NAME}}{{end}}
jobs:
  cache-builder-images:
    executor: releaser
    steps:
      - setup_remote_docker
      - checkout
      - write-build-layer-cache-keys
      {{- range $layers}}{{if eq .type "build-static-assets"}}
      - restore_cache:
          keys:
            {{- range .meta.circleci.CACHE_KEY_PREFIX_LIST}}
            - {{template "cache-key" .}}
            {{- end}}
      - run:
          name: Finish early if loaded exact match from cache.
          command: |
            if [ -f {{.archivefile}} ]; then
              echo "Exact match found in cache, skipping build."
              circleci-agent step halt
            fi
      - run: BUILD_LAYER_ID={{.name}} make -C release load-builder-cache
      - run: make -f release/layer.mk {{.name}}-image
      - run: make -f release/layer.mk {{.name}}-save
      - save_cache:
          key: {{template "cache-key" (index .meta.circleci.CACHE_KEY_PREFIX_LIST 0)}}
          paths:
            - {{.archivefile}}
      {{- end}}{{end}}

{{- range $packages}}
  {{.meta.BUILD_JOB_NAME}}:
    executor: releaser
    environment:
      - PACKAGE_SPEC_ID: {{.packagespecid}}
    steps:
      - setup_remote_docker
      - checkout

      # Restore the package cache first, we might not need to rebuild.
      - write-package-cache-key
      - restore_cache:
          key: '{{template "cache-key" .meta.circleci.PACKAGE_CACHE_KEY}}'
      - run:
          name: Check the cache status.
          command: |
            if ! { PKG=$(find .buildcache/packages/store -maxdepth 1 -mindepth 1 -name '*.zip' 2> /dev/null) && [ -n "$PKG" ]; }; then
              echo "No package found, continuing with build."
              exit 0
            fi
            # Check the aliases are right, as they are metadata not included in
            # the cache key. If they're wrong, it's time to bust cache.
            for ALIAS in {{ range .aliases }}.buildcache/packages/by-alias/{{.path}} {{end}}; do
              if ! readlink $ALIAS; then
                echo "Missing alias: $ALIAS"
                echo "Please increment the cache version to fix this issue."
                exit 1
              fi
            done
            echo "Package already cached, skipping build."
            circleci-agent step halt

      # We need to rebuild, so load the builder cache.
      - write-build-layer-cache-keys
      - restore_cache:
          keys:
          {{- range .meta.circleci.BUILDER_CACHE_KEY_PREFIX_LIST}}
          - {{template "cache-key" .}}
          {{- end}}
      - run: make -C release load-builder-cache
      - run: make -C release package
      - run: ls -lahR .buildcache/packages
      # Save package cache.
      - save_cache:
          key: '{{template "cache-key" .meta.circleci.PACKAGE_CACHE_KEY}}'
          paths:
            - .buildcache/packages
      - store_artifacts:
          path: .buildcache/packages
          destination: packages
      # Save builder image cache if necessary.
      # The range should only iterate over a single layer.
      {{- $pkg := . -}}
      {{- range $idx, $layerInfo := .meta.builtin.BUILD_LAYERS }}
      {{- if eq $layerInfo.type "warm-go-build-vendor-cache" }}
      {{- with $layerInfo }}
      {{- $circleCICacheKey := (index $pkg.meta.circleci.BUILDER_CACHE_KEY_PREFIX_LIST $idx) }}
      - run:
          name: Check builder cache status
          command: |
            if [ -f {{.archive}} ]; then
              echo "Builder image already cached, skipping cache step."
              circleci-agent step halt
            fi
      - run: make -f release/layer.mk {{.name}}-save
      - save_cache:
          key: '{{template "cache-key" $circleCICacheKey}}'
          paths:
            - {{.archive}}
      {{- end}}
      {{- end}}
      {{- end}}
{{end}}

  bundle-releases:
    executor: releaser
    steps:
      - checkout
      - write-all-package-cache-keys
      {{- range $packages}}
      - load-{{.meta.BUILD_JOB_NAME}}{{end}}
      - run: ls -lahR .buildcache/packages
      - store_artifacts:
          path: .buildcache/packages
          destination: packages
      - run: tar -czf packages.tar.gz .buildcache/packages
      - store_artifacts:
          path: packages.tar.gz
          destination: packages.tar.gz

commands:
  {{- range $packages }}
  load-{{.meta.BUILD_JOB_NAME}}:
    steps:
      - restore_cache:
          key: '{{template "cache-key" .meta.circleci.PACKAGE_CACHE_KEY}}'
  {{end}}

  write-build-layer-cache-keys:
    steps:
      - run:
          name: Write builder layer cache keys
          command: make -C release write-builder-cache-keys

  write-package-cache-key:
    steps:
      - run:
          name: Write package cache key
          command: make -C release write-package-cache-key

  write-all-package-cache-keys:
    steps:
      - run:
          name: Write package cache key
          command: make -C release write-all-package-cache-keys
