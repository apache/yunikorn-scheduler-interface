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

## How do I contribute code?
You need to first sign and return an
[ICLA](https://github.infra.cloudera.com/yunikorn-core/blob/master/CLAs/Cloudera%20ICLA_25APR2018.pdf)
and
[CCLA](https://github.infra.cloudera.com/yunikorn-core/blob/master/CLAs/Cloudera%20CCLA_25APR2018.pdf)
before we can accept and redistribute your contribution. Once these are submitted you are
free to start contributing to scheduler-interface. Submit these to CLA@cloudera.com.

### Find
We use Github issues to track bugs for this project. Find an issue that you would like to
work on (or file one if you have discovered a new issue!). If no-one is working on it,
assign it to yourself only if you intend to work on it shortly.

It’s a good idea to discuss your intended approach on the issue. You are much more
likely to have your patch reviewed and committed if you’ve already got buy-in from the
yunikorn community before you start.

### Fix
Now start coding! As you are writing your patch, please keep the following things in mind:

First, please include tests with your patch. If your patch adds a feature or fixes a bug
and does not include tests, it will generally not be accepted. If you are unsure how to
write tests for a particular component, please ask on the issue for guidance.

Second, please keep your patch narrowly targeted to the problem described by the issue.
It’s better for everyone if we maintain discipline about the scope of each patch. In
general, if you find a bug while working on a specific feature, file a issue for the bug,
check if you can assign it to yourself and fix it independently of the feature. This helps
us to differentiate between bug fixes and features and allows us to build stable
maintenance releases.

Finally, please write a good, clear commit message, with a short, descriptive title and
a message that is exactly long enough to explain what the problem was, and how it was
fixed.

Please create a pull request on github with your patch.
