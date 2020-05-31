<!--
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 -->

# Yunikorn Scheduler Interface
Yunikorn Scheduler Interface defines protobuf interfaces for the communication between the yunikorn-core and the resource management systems.

For detailed information on the components and how to build the overall scheduler please see the [yunikorn-core](https://github.com/apache/incubator-yunikorn-core).

## Interface description
The interface has two parts:
* an API based interface for locally deployed go based interactions.
* a RPC based interface for remotely deployed or cross language interactions.

Both interfaces are build from the same source.

The source and documentation are included in one file the [scheduler-interface-spec](./scheduler-interface-spec.md)

The protocol definition is extracted from the documentation by the build. The extracted protocol definition and the source code generated from the definition are part of the repository but should not be modified directly. 

## Modifying the Interface
The interface is defined in the specification as blocks of type `protobuf` as follows:
````
```protobuf
defintion following the protobuf specifications
```
````
The blocks of definitions are extracted from the specification file and added together to form the protobuf input. The definitions cannot have lines exceeding 200 characters.

## How to use 
The output of this build is required to build the scheduler and the shims for the resource manager(s).
However to allow building those projects against a predefined interface and without the requirement of generating the interface artifacts in each build the generated artifacts are part of the repository for direct use.

### Go based components
The dependent projects can use the interface by importing _github.com/apache/incubator-yunikorn-scheduler-interface/lib/go/si_ as part of the code:
```go
package example

import "github.com/apache/incubator-yunikorn-scheduler-interface/lib/go/si"
```

### Java based components
To be added: currently only the go source code artifact is generated.

## How to build
The scheduler interface is used by all other components of yunikorn. For building the scheduler and its shims please check the instructions in the [How to build](https://github.com/apache/incubator-yunikorn-core#Building-and-using-Yunikorn) section in the yunikorn-core repository.

The build process will download and install all required tools to build the artifact. Building the interface should only be required if the interface has been modified.

Prerequisite: 
- Go 1.11+

Steps: 
- Run `make` to build.

Including the modified interface in other components without updating the repository is possible by replacing the artifact checked out from the repository with the newly generated artifact.
The exact procedure depends on the language the component is written in.

## How do I contribute code?

See how to contribute code from [this guide](docs/how-to-contribute.md).
