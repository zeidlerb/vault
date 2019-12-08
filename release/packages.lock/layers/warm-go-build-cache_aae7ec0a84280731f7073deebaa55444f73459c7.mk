
LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_ID             := warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7
LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_BASE_LAYER     := build-static-assets_75d9c94c66bdd9437e93c84679569553964385f2
LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_SOURCE_INCLUDE := .
LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_SOURCE_EXCLUDE := 
LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_CACHE_KEY_FILE := .buildcache/cache-keys/warm-go-build-cache-aae7ec0a84280731f7073deebaa55444f73459c7
LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_ARCHIVE_FILE   := .buildcache/archives/warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7.tar.gz
$(eval $(call LAYER,$(LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_ID),$(LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_BASE_LAYER),$(LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_SOURCE_INCLUDE),$(LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_SOURCE_EXCLUDE),$(LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_CACHE_KEY_FILE),$(LAYER_warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_ARCHIVE_FILE)))

BUILD_LAYER_IMAGE = $(warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_IMAGE)
BUILD_LAYER_IMAGE_NAME = $(warm-go-build-cache_aae7ec0a84280731f7073deebaa55444f73459c7_IMAGE_NAME)

