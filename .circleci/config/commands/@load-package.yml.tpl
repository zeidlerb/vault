{{ $data := (datasource "package-list" )}}
{{ $packages := $data.packages }}
{{ $revision := $data.productrevision }}
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
        command: PRODUCT_REVISION={{$revision}} make -C release write-builder-cache-keys
    - run:
        name: Write package cache keys
        command: PRODUCT_REVISION={{$revision}} make -C release write-package-cache-keys
