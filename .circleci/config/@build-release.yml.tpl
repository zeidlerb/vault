{{$data := (datasource "package-list")}}
{{$packages := $data.packages }}
{{$layers := $data.layers -}}
{{$revision := $data.productrevision}}
# Any change to $cacheVersion invalidates all build layer and package caches.
{{$cacheVersion := "buildcache-v1" -}}
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
      - {{.inputs.BUILD_JOB_NAME}}: { requires: [ cache-builder-images ] }{{end}}
      - bundle-releases:
          requires:
            {{- range $packages}}
            - {{.inputs.BUILD_JOB_NAME}}{{end}}
jobs:
  cache-builder-images:
    executor: releaser
    steps:
      - setup_remote_docker
      - checkout
      - write-cache-keys
      {{- range $layers}}{{if eq .type "static"}}
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

  bundle-releases:
    executor: releaser
    steps:
      - checkout
      - write-cache-keys
      {{- range $packages}}
      - "load-{{.inputs.BUILD_JOB_NAME}}"{{end}}
      - run: ls -lahR dist/
      - run: tar -czf dist.tar.gz dist
      - store_artifacts:
          path: dist
          destination: dist
      - store_artifacts:
          path: dist.tar.gz
          destination: dist.tar.gz

{{- range $packages}}
  {{.inputs.BUILD_JOB_NAME}}:
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
      - run: make -f release/layer.mk {{.inputs.BUILDER_LAYER_ID}}-load || echo "No cached builder image to load."
      - run: make -C release package
      - run: ls -lahR dist/
      - store_artifacts:
          path: {{.inputs.PACKAGE_OUT_ROOT}}
          destination: {{.inputs.PACKAGE_OUT_ROOT}}
      # Save builder image cache.
      - save_cache:
          key: '{{$cacheVersion}}-{{index .meta.circleci.BUILDER_CACHE_KEY_PREFIX_LIST 0}}'
          paths:
            - .buildcache/archives/{{.inputs.BUILDER_LAYER_ID}}.tar.gz
      # Save package cache.
      - save_cache:
          key: '{{.meta.circleci.PACKAGE_CACHE_KEY}}'
          paths:
            - {{.inputs.PACKAGE_OUT_ROOT}}
{{end}}

commands:
  {{- range $packages }}
  load-{{.inputs.BUILD_JOB_NAME}}:
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
