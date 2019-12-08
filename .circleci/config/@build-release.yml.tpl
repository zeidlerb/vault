{{- $data := (datasource "package-list") -}}
{{- $packages := $data.packages -}}
{{- $layers := $data.layers -}}
{{- $revision := $data.productrevision -}}
{{- $cacheVersion := "test-v1" -}}
# Any change to $cacheVersion invalidates all build layer and package caches.
# Current $cacheVersion: {{$cacheVersion}}

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
      - write-cache-keys
      {{- range $layers}}{{if eq .type "build-static-assets"}}
      - restore_cache:
          keys:
            {{- range .meta.circleci.CACHE_KEY_PREFIX_LIST}}
            - {{$cacheVersion}}-{{.}}
            {{- end}}
      - run: make -f release/layer.mk {{.name}}-load || echo "No cached builder image to load."
      - run: make -f release/layer.mk {{.name}}-image
      - run: make -f release/layer.mk {{.name}}-save
      - save_cache:
          key: {{$cacheVersion}}-{{index .meta.circleci.CACHE_KEY_PREFIX_LIST 0}}
          paths:
            - {{.archivefile}}
      {{- end}}{{end}}

{{- range $packages}}
  {{.meta.BUILD_JOB_NAME}}:
    executor: releaser
    environment:
      - PACKAGE_SPEC_ID: {{.packagespecid}}
      {{- range $NAME, $VALUE := .inputs -}}
        {{- $type := (printf "%T" $VALUE)  -}}
        {{- if or (eq $type "string") (eq $type "int") }}
      - {{$NAME}}: '{{conv.ToString $VALUE}}'
        {{- end}}
      {{- end}}
    steps:
      - setup_remote_docker
      - checkout
      - write-cache-keys
      - restore_cache:
          keys:
          {{- range .meta.circleci.BUILDER_CACHE_KEY_PREFIX_LIST}}
          - {{$cacheVersion}}-{{.}}
          {{- end}}
      - restore_cache:
          key: '{{.meta.circleci.PACKAGE_CACHE_KEY}}'
      - run: make -C release load-builder-cache || echo "No cached builder image to load."
      - run: make -C release package
      - run: ls -lahR .buildcache/packages
      - store_artifacts:
          path: .buildcache/packages
          destination: packages
      # Save builder image cache.
      - save_cache:
          key: '{{$cacheVersion}}-{{index .meta.circleci.BUILDER_CACHE_KEY_PREFIX_LIST 0}}'
          paths:
            - {{ (index .meta.builtin.BUILD_LAYERS 0).archive}}
      # Save package cache.
      - save_cache:
          key: '{{.meta.circleci.PACKAGE_CACHE_KEY}}'
          paths:
            - .buildcache/packages
{{end}}

  bundle-releases:
    executor: releaser
    steps:
      - checkout
      - write-cache-keys
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
          key: '{{.meta.circleci.PACKAGE_CACHE_KEY}}'
  {{end}}
  
  write-cache-keys:
    steps:
      - run:
          name: Write builder layer cache keys
          command: make -C release write-builder-cache-keys
      - run:
          name: Write package cache keys
          command: make -C release write-package-cache-keys
