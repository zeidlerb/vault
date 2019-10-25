ARG BASE_IMAGE
FROM $BASE_IMAGE
COPY . ./
RUN make static-dist

ENTRYPOINT /bin/bash
CMD make bin
