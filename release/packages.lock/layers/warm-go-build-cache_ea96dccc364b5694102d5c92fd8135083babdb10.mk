
LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_ID             := warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10
LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_BASE_LAYER     := build-static-assets_75d9c94c66bdd9437e93c84679569553964385f2
LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_SOURCE_INCLUDE := .
LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_SOURCE_EXCLUDE := 
LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_CACHE_KEY_FILE := .buildcache/cache-keys/warm-go-build-cache-ea96dccc364b5694102d5c92fd8135083babdb10
LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_ARCHIVE_FILE   := .buildcache/archives/warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10.tar.gz
$(eval $(call LAYER,$(LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_ID),$(LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_BASE_LAYER),$(LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_SOURCE_INCLUDE),$(LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_SOURCE_EXCLUDE),$(LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_CACHE_KEY_FILE),$(LAYER_warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_ARCHIVE_FILE)))

BUILD_LAYER_IMAGE = $(warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_IMAGE)
BUILD_LAYER_IMAGE_NAME = $(warm-go-build-cache_ea96dccc364b5694102d5c92fd8135083babdb10_IMAGE_NAME)

