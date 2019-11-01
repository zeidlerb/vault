# Static
#
# Building this image adds the full source code, plus all generated static files, including the UI.
#
# Running this image compiles the Go source code. You should pass environment variables to
# the docker run command via -e flags in order to set things like GOOS, GOARCH, CGO_ENABLED etc.
# After it's run, you can copy files out of the container using 'docker cp'.

ARG BASE_IMAGE
FROM $BASE_IMAGE
COPY . ./
RUN cd ui && yarn run build
RUN make static-assets

