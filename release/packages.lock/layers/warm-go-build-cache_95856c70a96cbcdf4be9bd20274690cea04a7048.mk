
LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_ID             := warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048
LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_BASE_LAYER     := build-static-assets_75d9c94c66bdd9437e93c84679569553964385f2
LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_SOURCE_INCLUDE := .
LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_SOURCE_EXCLUDE := 
LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_CACHE_KEY_FILE := .buildcache/cache-keys/warm-go-build-cache-95856c70a96cbcdf4be9bd20274690cea04a7048
LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_ARCHIVE_FILE   := .buildcache/archives/warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048.tar.gz
$(eval $(call LAYER,$(LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_ID),$(LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_BASE_LAYER),$(LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_SOURCE_INCLUDE),$(LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_SOURCE_EXCLUDE),$(LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_CACHE_KEY_FILE),$(LAYER_warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_ARCHIVE_FILE)))

BUILD_LAYER_IMAGE = $(warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_IMAGE)
BUILD_LAYER_IMAGE_NAME = $(warm-go-build-cache_95856c70a96cbcdf4be9bd20274690cea04a7048_IMAGE_NAME)

