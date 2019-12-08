
LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_ID             := warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812
LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_BASE_LAYER     := build-static-assets_75d9c94c66bdd9437e93c84679569553964385f2
LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_SOURCE_INCLUDE := .
LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_SOURCE_EXCLUDE := 
LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_CACHE_KEY_FILE := .buildcache/cache-keys/warm-go-build-cache-fd759168c4fae58081fa4b258662bb499176f812
LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_ARCHIVE_FILE   := .buildcache/archives/warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812.tar.gz
$(eval $(call LAYER,$(LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_ID),$(LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_BASE_LAYER),$(LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_SOURCE_INCLUDE),$(LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_SOURCE_EXCLUDE),$(LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_CACHE_KEY_FILE),$(LAYER_warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_ARCHIVE_FILE)))

BUILD_LAYER_IMAGE = $(warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_IMAGE)
BUILD_LAYER_IMAGE_NAME = $(warm-go-build-cache_fd759168c4fae58081fa4b258662bb499176f812_IMAGE_NAME)

