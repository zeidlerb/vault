
LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_ID             := warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb
LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_BASE_LAYER     := build-static-assets_75d9c94c66bdd9437e93c84679569553964385f2
LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_SOURCE_INCLUDE := .
LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_SOURCE_EXCLUDE := 
LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_CACHE_KEY_FILE := .buildcache/cache-keys/warm-go-build-cache-3f8aca10d04109aa9de077c141a6b91bf7da9bfb
LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_ARCHIVE_FILE   := .buildcache/archives/warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb.tar.gz
$(eval $(call LAYER,$(LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_ID),$(LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_BASE_LAYER),$(LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_SOURCE_INCLUDE),$(LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_SOURCE_EXCLUDE),$(LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_CACHE_KEY_FILE),$(LAYER_warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_ARCHIVE_FILE)))

BUILD_LAYER_IMAGE = $(warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_IMAGE)
BUILD_LAYER_IMAGE_NAME = $(warm-go-build-cache_3f8aca10d04109aa9de077c141a6b91bf7da9bfb_IMAGE_NAME)

