{{ $packages := (datasource "package-list" ).packages }}
{{- range $packages }}
load-{{.BUILD_JOB_NAME}}:
  steps:
    - restore_cache:
        key: '{{.PACKAGE_CACHE_KEY}}'
{{end}}
