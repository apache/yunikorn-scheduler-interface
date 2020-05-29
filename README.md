# YuniKorn Scheduler Interface
YuniKorn Scheduler Interface defines protobuf interfaces for the communication between the yunikorn-core and the resource management systems.

For detailed information on the components and how to build the overall scheduler please see the [yunikorn-core](https://github.com/apache/incubator-yunikorn-core).

## Interface description
The interface defines messages for two implementations:
* an API based interface for locally deployed go based interactions.
* an RPC based interface for remotely deployed or cross language interactions.

Both implementations are build from the same source.

Messages might require standardised constants used as identifiers.
The specification declares constants that are used by the core and one or more resource management system.
Constants used by just the core or one resource management system are not part of the interface specification.
Default values for any part of the messages are not part of the specification. 

The source and documentation are part of the same file the [scheduler-interface-spec](./scheduler-interface-spec.md).
The build process extracts the messages and the constants from the file. 

The extracted protocol definition with the source code generated from the definition are part of the repository but should not be modified directly. 

## Modifying the Interface
The messages and constants used in those messages must be updated in the documentation. 
The messages must be defined in the specification as blocks of type `protobuf` as follows:
````
```protobuf
defintion following the protobuf specifications
```
````
Those blocks of definitions will be extracted from the specification file and added together to form the protobuf input.
The definitions cannot have lines exceeding 200 characters.

The messages must be defined in the specification as blocks of type `constants` as follows:
````
```constants
constant(s) definition
```
````
A constant block must be a legal go definition of one or more constants.
All blocks will be extracted from the specification file and added together as a go source file.
The build process will perform a syntax check on the generated go file.

## How to use 
The output of this build is required to build the scheduler and the shims for the resource manager(s).
However, to allow building those projects against a predefined interface and without the requirement of generating the interface artifacts in each build the generated artifacts are part of the repository for direct use.

### Go based components
The dependent projects can use the interface by importing _github.com/apache/incubator-yunikorn-scheduler-interface/lib/go/si_ as part of the code:
```go
package example

import "github.com/apache/incubator-yunikorn-scheduler-interface/lib/go/si"
import "github.com/apache/incubator-yunikorn-scheduler-interface/lib/go/common"
```

### Java based components
To be added: currently only the go artifacts will be generated.

## How to build
The scheduler interface is a required component for all other components of YuniKorn. For building the scheduler and its shims please check the instructions in the [How to build](https://github.com/apache/incubator-yunikorn-core/blob/master/docs/developer-guide.md) section in the yunikorn-core repository.

The build process will download and install all required tools to build this artifact. Building the interface should only be required if the interface has been modified.

Prerequisite: 
- Go 1.11+

Steps: 
- Run `make` to build.

Including the modified interface in other components without updating the repository is possible by replacing the artifact checked out from the repository with the newly generated artifact.
The exact procedure is language dependent. Check the build instructions for details. 

## How do I contribute code?

See how to contribute code from [this guide](docs/how-to-contribute.md).
