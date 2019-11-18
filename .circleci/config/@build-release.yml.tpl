{{- $packages := (datasource "package-list" ).packages -}}
{{- $layers := (datasource "package-list" ).layers -}}
{{- $cacheVersion := "buildcache-v0" -}}
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
      - {{.BUILD_JOB_NAME}}: { requires: [ cache-builder-images ] }{{end}}
      - bundle-releases:
          requires:
            {{- range $packages}}
            - {{.BUILD_JOB_NAME}}{{end}}
jobs:
  cache-builder-images:
    executor: releaser
    steps:
      - setup_remote_docker
      - checkout
      - write-cache-keys
      - restore_cache:
          keys:
          {{- $count := 0 -}}
          {{- $index := 0}}
           - {{$cacheVersion}}-{{range $layers}}{{$count = (math.Add $count 1) -}}
              {{.type}}-{{ "{{ checksum .buildcache/" }}{{.type}}_{{.checksum}}-cache-key{{"}}"}}
              {{- end}}{{$index = $count -}}
              {{- range $layers -}}
              {{- $count = 0 -}}
              {{- $index = (math.Sub $index 1) -}}
              {{- if ge $index 1}}
            - {{$cacheVersion -}}
                {{- range $layers}}{{$count = (math.Add $count 1) -}}
                  {{- if le $count $index -}}
                    -{{.type}}-{{ "{{ checksum .buildcache/" }}{{.type}}_{{.checksum}}-cache-key{{"}}"}}
                  {{- end -}}
                {{- end -}}
              {{- end -}}
            {{- end}}
      - load-builder-cache
      - save-builder-cache

  bundle-releases:
    executor: releaser
    steps:
      - checkout
      - write-cache-keys
      {{- range $packages}}
      - "load-{{.BUILD_JOB_NAME}}"{{end}}
      - run: ls -lahR dist/

{{- range $packages}}
  {{.BUILD_JOB_NAME}}:
    executor: releaser
    environment:
      {{- range $NAME, $VALUE := .}}
      - {{$NAME}}: "{{conv.ToString $VALUE}}"
      {{- end}}
    steps:
      - setup_remote_docker
      - checkout
      - write-cache-keys
      - restore_cache:
          keys:
          {{- $segments := .CIRCLECI_CACHE_KEY_SEGMENTS -}}
          {{- $count := 0 -}}
          {{- $index := 0}}
           - {{$cacheVersion}}-{{range $segments}}{{$count = (math.Add $count 1) -}}
              {{.}}
              {{- end}}{{$index = $count -}}
              {{- range $segments -}}
              {{- $count = 0 -}}
              {{- $index = (math.Sub $index 1) -}}
              {{- if ge $index 1}}
            - {{$cacheVersion -}}
                {{- range $segments }}{{$count = (math.Add $count 1) -}}
                  {{- if le $count $index -}}
                    -{{.}}
                  {{- end -}}
                {{- end -}}
              {{- end -}}
            {{- end}}
      - load-builder-cache
      - run:
          name: Compile package
          command: |
            make build
      - run:
          name: Dump contents of dist/
          command: ls -lahR dist/
      - store_artifacts:
          path: {{.PACKAGE_OUT_ROOT}}
          destination: {{.PACKAGE_OUT_ROOT}}
      - save_cache:
          key: '{{.PACKAGE_CACHE_KEY}}'
          paths:
            - {{.PACKAGE_OUT_ROOT}}
{{end}}

