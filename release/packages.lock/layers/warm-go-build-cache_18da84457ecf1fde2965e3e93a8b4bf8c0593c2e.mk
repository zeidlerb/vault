
LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_ID             := warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e
LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_BASE_LAYER     := build-static-assets_75d9c94c66bdd9437e93c84679569553964385f2
LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_SOURCE_INCLUDE := .
LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_SOURCE_EXCLUDE := 
LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_CACHE_KEY_FILE := .buildcache/cache-keys/warm-go-build-cache-18da84457ecf1fde2965e3e93a8b4bf8c0593c2e
LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_ARCHIVE_FILE   := .buildcache/archives/warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e.tar.gz
$(eval $(call LAYER,$(LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_ID),$(LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_BASE_LAYER),$(LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_SOURCE_INCLUDE),$(LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_SOURCE_EXCLUDE),$(LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_CACHE_KEY_FILE),$(LAYER_warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_ARCHIVE_FILE)))

BUILD_LAYER_IMAGE = $(warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_IMAGE)
BUILD_LAYER_IMAGE_NAME = $(warm-go-build-cache_18da84457ecf1fde2965e3e93a8b4bf8c0593c2e_IMAGE_NAME)

