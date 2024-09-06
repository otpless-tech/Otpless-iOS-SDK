# Define your commands
POD_LIB_LINT = pod lib lint
POD_TRUNK_PUSH = pod trunk push
POD_REPO_UPDATE = pod repo update

# Define the sequence for publishing
publish: push

push:
	@$(POD_LIB_LINT) && \
	echo "Validation passed, moving onto next step: pod repo update" && \
	$(POD_REPO_UPDATE) && \
	echo "Pod repo update successful, moving onto next step: pod trunk push" && \
	$(POD_TRUNK_PUSH)