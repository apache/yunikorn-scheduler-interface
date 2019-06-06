# Yunikorn Scheduler Interface
Yunikorn Resource Scheduler Interface defines a protobuf interface for communication between the core scheduler and the resource management systems.

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

## How to build
Prerequisite: 
- Go 1.9+
  
Steps: 
- Run `make` to build.

The build process will download and install all required tools to build. 
Currently only the go source code artifact is generated.

## How to use 
The output of this build is required to build the scheduler and the resource manager(s). To allow building those projects without the requirement of generating the interface artifacts in each the generated artifacts are part of the repository.

The dependent projects can use the interface by importing "github.infra.cloudera.com/yunikorn/scheduler-interface/lib/go/si"
```go
package example

import "github.infra.cloudera.com/yunikorn/scheduler-interface/lib/go/si"
```