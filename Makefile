# Variables
WORKSPACE_NAME = Example/OtplessSDK.xcworkspace
SCHEME_NAME = OtplessSDK-Example
CONFIGURATION = Debug
ARCHIVE_PATH = $(PWD)/build/$(SCHEME_NAME).xcarchive
PLIST_PATH = $(PWD)/Example/OtplessSDK/Info.plist

# Get the Git branch name and format it for the folder name
BRANCH_NAME = $(shell git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' | sed 's/^feat\///;s/^fix\///')
IPA_DIR = $(IPA_BASE_DIR)/$(BRANCH_NAME)_RC

# CocoaPod deployment
deploy-pod:
	@pod lib lint
	@if [ $$? -eq 0 ]; then \
		echo "Pod validation successful. Proceeding with publishing..."; \
		pod trunk push; \
	else \
		echo "Pod validation failed. Please fix the errors and try again."; \
		exit 1; \
	fi

# Prepare for archive by updating app info and cleaning project
prepare: update-app-info clean

# Clean project
clean:
	@echo "Cleaning project..."
	@xcodebuild -workspace $(WORKSPACE_NAME) -scheme $(SCHEME_NAME) clean

# Update app info (version, bundle ID)
update-app-info:
	@echo "Updating app information..."
	@BRANCH_NAME=$$(git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]' | sed 's/^feat\///;s/^fix\///'); \
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0.$$BRANCH_NAME" $(PLIST_PATH)
	@CURRENT_VERSION=$$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" $(PLIST_PATH)); \
	NEW_VERSION=$$((CURRENT_VERSION + 1)); \
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $$NEW_VERSION" $(PLIST_PATH)
	@echo "Updated bundle identifier, version string, and build number."
