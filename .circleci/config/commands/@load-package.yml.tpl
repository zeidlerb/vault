{{ $packages := (datasource "package-list" ).packages }}
{{- range $packages }}
load-{{.inputs.BUILD_JOB_NAME}}:
  steps:
    - restore_cache:
        key: '{{.meta.circleci.PACKAGE_CACHE_KEY}}'
{{end}}
