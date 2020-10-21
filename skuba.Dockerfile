ARG GOLANG_IMAGE=golang:1.15.3
FROM $GOLANG_IMAGE

# adding the files into the container makes the cache invalid.
# we may be better trying something different here so we dont keep on rebuilding the image on each run
ADD skuba /skuba
WORKDIR /skuba
RUN zypper install -y make git-core
RUN make release
RUN skuba version
ENTRYPOINT ["skuba"]



