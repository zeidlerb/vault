{{ $packages := (datasource "package-list" ).packages }}
workflows:
  build-release:
    jobs:
      - cache-builder-images
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
      - ensure-builder-image-cache
  bundle-releases:
    executor: releaser
    steps:
      - checkout
      - write-builder-cache-keys
      {{- range $packages}}
      - load-package:
          PACKAGE_NAME: {{.PACKAGE_NAME}}
          PACKAGE_SPEC_ID: {{.PACKAGE_SPEC_ID}}{{end}}
      - run: ls -lahR dist/
