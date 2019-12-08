ARG BASE_IMAGE
FROM $BASE_IMAGE
COPY . ./
# The go cache is only really useful for matching GOOS and GOARCH,
# so we just need to refer to them here to invalidate the cache based
# on them, or we would end up caching junk that wouldn't be reusable.
ENV GOOS=openbsd
ENV GOARCH=386
RUN go build -v