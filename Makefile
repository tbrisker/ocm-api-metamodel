#
# Copyright (c) 2019 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Details of the version of 'antlr' to use:
antlr_version:=4.7.2
antlr_url:=https://www.antlr.org/download/antlr-$(antlr_version)-complete.jar
antlr_sum:=6852386d7975eff29171dae002cc223251510d35f291ae277948f381a7b380b4

# Explicitly enable Go modules so that compilation will work correctly even when
# the project directory is inside the directory indicated by the 'GOPATH'
# environment variable:
export GO111MODULE=on

.PHONY: cmds
cmds: generate
	for cmd in $$(ls cmd); do \
		go build -o "$${cmd}" "./cmd/$${cmd}" || exit 1; \
	done

.PHONY: generate
generate: antlr
	cd pkg/language && \
	java \
		-jar ../../$? \
		-package language \
		*.g4

antlr:
	wget --output-document="$@" "$(antlr_url)"
	echo "$(antlr_sum) $@" | sha256sum --check

.PHONY: fmt
fmt:
	gofmt -s -l -w \
		./cmd \
		./pkg \
		./tests \
		$(NULL)

.PHONY: tests
tests: unit_tests model_tests

.PHONY: unit_tests
unit_tests:
	ginkgo -r pkg

.PHONY: model_tests
model_tests: cmds
	rm -rf tests/api
	./ocm-metamodel-tool generate \
		--model=tests/model \
		--base=github.com/openshift-online/ocm-api-metamodel/tests/api \
		--output=tests/api \
		--docs=tests/docs
	ginkgo -r tests

.PHONY: clean
clean:
	rm -rf \
		$$(ls cmd) \
		.gobin \
		antlr \
		model \
		tests/api \
		$(NULL)
