{{ $packages := (datasource "package-list" ).packages }}
{{- range $packages }}
{{.JOB_NAME}}:
  executor: releaser
  environment:
    {{range $NAME, $VALUE := . -}}
    - {{$NAME}}="{{$VALUE}}"{{end}}
  steps:
    - build-package:
        PACKAGE_SPEC_ID: {{.PACKAGE_SPEC_ID}}
{{ end -}}
