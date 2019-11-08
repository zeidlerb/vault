{{ $packages := (datasource "package-list" ).packages }}
workflows:
  build-release:
    jobs:
      - cache-builder-images
      {{- range $packages}}
      - {{.JOB_NAME}}: { requires: [ cache-builder-images ] }{{end}}
      - bundle-releases:
          requires:
            {{- range $packages}}
            - {{.JOB_NAME}}{{end}}
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
      - load-packages
      - run: ls -lahR dist/
