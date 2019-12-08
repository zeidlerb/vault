
LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_ID             := warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06
LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_BASE_LAYER     := build-static-assets_b64cf5613ebbe8b30d65b184a6714fee7d605fac
LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_SOURCE_INCLUDE := .
LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_SOURCE_EXCLUDE := 
LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_CACHE_KEY_FILE := .buildcache/cache-keys/warm-go-build-cache-5d780828053face1c84cd13ce898115811c10d06
LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_ARCHIVE_FILE   := .buildcache/archives/warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06.tar.gz
$(eval $(call LAYER,$(LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_ID),$(LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_BASE_LAYER),$(LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_SOURCE_INCLUDE),$(LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_SOURCE_EXCLUDE),$(LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_CACHE_KEY_FILE),$(LAYER_warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_ARCHIVE_FILE)))

BUILD_LAYER_IMAGE = $(warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_IMAGE)
BUILD_LAYER_IMAGE_NAME = $(warm-go-build-cache_5d780828053face1c84cd13ce898115811c10d06_IMAGE_NAME)

