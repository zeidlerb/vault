
LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_ID             := warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120
LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_BASE_LAYER     := build-static-assets_b64cf5613ebbe8b30d65b184a6714fee7d605fac
LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_SOURCE_INCLUDE := .
LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_SOURCE_EXCLUDE := 
LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_CACHE_KEY_FILE := .buildcache/cache-keys/warm-go-build-cache-fc24001f7863daadab46acabce457acbd29d1120
LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_ARCHIVE_FILE   := .buildcache/archives/warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120.tar.gz
$(eval $(call LAYER,$(LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_ID),$(LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_BASE_LAYER),$(LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_SOURCE_INCLUDE),$(LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_SOURCE_EXCLUDE),$(LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_CACHE_KEY_FILE),$(LAYER_warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_ARCHIVE_FILE)))

BUILD_LAYER_IMAGE = $(warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_IMAGE)
BUILD_LAYER_IMAGE_NAME = $(warm-go-build-cache_fc24001f7863daadab46acabce457acbd29d1120_IMAGE_NAME)

