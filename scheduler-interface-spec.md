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

# Scheduler Interface Spec

Authors: The Yunikorn Scheduler Authors

## Objective

To define a standard interface that can be used by different types of resource management systems such as YARN/K8s.

### Goals for minimum viable product (MVP)

- Interface and implementation should be resource manager (RM) agnostic.
- Interface can handle multiple types of resource managers from multiple zones, and different policies can be configured in different zones.

Possible use cases:
- A large cluster needs multiple schedulers to achieve horizontally scalability.
- Multiple resource managers need to run on the same cluster. The managers grow and shrink according to runtime resource usage and policies.

### Non-Goals for minimum viable product (MVP)

- Handle process-specific information: Scheduler Interface only handles decisions for scheduling instead of how containers will be launched.

## Design considerations

Highlights:
- The scheduler should be as stateless as possible. It should try to eliminate any local persistent storage for scheduling decisions.
- When a RM starts, restarts or recovers the RM needs to sync its state with scheduler.

### Architecture

## Generic definitions

Interface and messages generic definition.

The syntax used for the declarations is `proto3`. The definition currently only provides go related info.
```protobuf
syntax = "proto3";
package si.v1;

import "google/protobuf/descriptor.proto";

option go_package = "lib/go/si";

extend google.protobuf.FieldOptions {
  // Indicates that a field MAY contain information that is sensitive
  // and MUST be treated as such (e.g. not logged).
  bool si_secret = 1059;
}
```

## Scheduler Interfaces

There are two kinds of interfaces, the first one is RPC based communication, the second one is API based.

RPC based, the [gRPC](https://grpc.io/) framework is used, will be useful when scheduler has to be deployed as a remote process.
For example when we need to deploy scheduler support multiple remote clusters.
A second example is when there is a cross language integration, like between Java and Go.

Unless specifically required we strongly recommend the use of the API based interface to avoid the overhead of the RPC serialization and de-serialization.

### RPC Interface

There are three sets of RPCs:

* **Scheduler Service**: RM can communicate with the Scheduler Service and do resource allocation/request update, etc.
* **Admin Service**: Admin can communicate with Scheduler Interface and get configuration updated.
* **Metrics Service**: Used to retrieve state of scheduler by users / RMs.

Currently only the design and implementation for the Scheduler Service is provided.

```protobuf
service Scheduler {
  // Register a RM, if it is a reconnect from previous RM the call will
  // trigger a cleanup of all in-memory data and resync with RM.
  rpc RegisterResourceManager (RegisterResourceManagerRequest)
    returns (RegisterResourceManagerResponse) { }

  // Update Scheduler status (this includes node status update, allocation request
  // updates, etc. And receive updates from scheduler for allocation changes,
  // any required status changes, etc.
  // Update allocation request
  rpc UpdateAllocation(stream AllocationRequest)
    returns (stream AllocationResponse) { }

  // Update application request
  rpc UpdateApplication(stream ApplicationRequest)
    returns (stream ApplicationResponse) { }

  // Update node info
  rpc UpdateNode(stream NodeRequest)
    returns (stream NodeResponse) { }
}
```
#### Why bi-directional gRPC

The reason of using bi-directional streaming gRPC is, according to performance benchmark: https://grpc.io/docs/guides/benchmarking.html latency is close to 0.5 ms.
The same performance benchmark shows streaming QPS can be 4x of non-streaming RPC.
Considering scheduler needs both throughput and better latency, we go with streaming API for scheduler related decisions.

### API Interface

The API interface only relies on the message definition and not on other generated code as the RPC Interface does.
Below is an example of the Scheduler Service as defined in the RPC. The SchedulerAPI is bi-directional and can be a-synchronous.
For the asynchronous cases the API requires a callback interface to be implemented in the resource manager.
The callback must be provided to the scheduler as part of the registration.


```golang
package api

import "github.com/apache/yunikorn-scheduler-interface/lib/go/si"

type SchedulerAPI interface {
	// Register a new RM, if it is a reconnect from previous RM, cleanup
	// all in-memory data and resync with RM.
	RegisterResourceManager(request *si.RegisterResourceManagerRequest, callback ResourceManagerCallback) (*si.RegisterResourceManagerResponse, error)

	// Update allocation request
	UpdateAllocation(request *si.AllocationRequest) error

	// Update application request
	UpdateApplication(request *si.ApplicationRequest) error

	// Update node info
	UpdateNode(request *si.NodeRequest) error

	// Notify scheduler to reload configuration and hot-refresh in-memory state based on configuration changes
	UpdateConfiguration(request *si.UpdateConfigurationRequest) error
}

// RM side needs to implement this API
type ResourceManagerCallback interface {

	//Receive Allocation Update Response
	UpdateAllocation(response *si.AllocationResponse) error

	//Receive Application Update Response
	UpdateApplication(response *si.ApplicationResponse) error

	//Receive Node Update Response
	UpdateNode(response *si.NodeResponse) error

	// Run a certain set of predicate functions to determine if a proposed allocation
	// can be allocated onto a node.
	Predicates(args *si.PredicatesArgs) error

	// Run predicate functions to determine if a proposed allocation can be allocated
	// onto a node after preemption. The request contains a list of allocations to
	// speculatively remove.
	PreemptionPredicates(args *si.PreemptionPredicatesArgs) *si.PreemptionPredicatesResponse

	// This plugin is responsible for transmitting events to the shim side.
	// Events can be further exposed from the shim.
	SendEvent(events []*si.EventRecord)

	// Scheduler core can update container scheduling state to the RM,
	// the shim side can determine what to do incorporate with the scheduling state

	// update container scheduling state to the shim side
	// this might be called even the container scheduling state is unchanged
	// the shim side cannot assume to only receive updates on state changes
	// the shim side implementation must be thread safe
	UpdateContainerSchedulingState(request *si.UpdateContainerSchedulingStateRequest)
}

// RM can additionally implement this API to provide information during state dumps
type StateDumpPlugin interface {

	// This plugin is responsible for returning a JSON representation of the state of the shim
	GetStateDump() (string, error)
}
```

### Communications between RM and Scheduler

Lifecycle of RM-Scheduler communication

```
Status of RM in scheduler:

                            Connection     timeout
    +-------+      +-------+ loss +-------+      +---------+
    |init   |+---->|Running|+---->|Paused |+---->| Stopped |
    +-------+      +----+--+      +-------+      +---------+
         RM register    |                             ^
         with scheduler |                             |
                        +-----------------------------+
                                   RM voluntarilly
                                     Shutdown
```

#### RM register with scheduler

When a new RM starts, fails, it will register with scheduler. In some cases, scheduler can ask RM to re-register because of connection issues or other internal issues.

```protobuf
message RegisterResourceManagerRequest {
  // An ID which can uniquely identify a RM **cluster**. (For example, if a RM cluster has multiple manager instances for HA purpose, they should use the same information when do registration).
  // If RM register with the same ID, all previous scheduling state in memory will be cleaned up, and expect RM report full scheduling state after registration.
  string rmID = 1;

  // Version of RM scheduler interface client.
  string version = 2;

  // Policy group name:
  // This defines which policy to use. Policy should be statically configured. (Think about network security group concept of ec2).
  // Different RMs can refer to the same policyGroup if their static configuration is identical.
  string policyGroup = 3;

  // Pass the build information of k8shim to core.
  map<string, string> buildInfo = 4;

  // Pass the serialized configuration for this policyGroup to core.
  string config = 5;

  // Additional configuration key/value pairs for configuration not related to the policyGroup.
  map<string, string> extraConfig = 6;
}

// Upon success, scheduler returns RegisterResourceManagerResponse to RM, otherwise RM receives exception.
message RegisterResourceManagerResponse {
  // Intentionally empty.
}
```

#### RM and scheduler updates.

Below is overview of how scheduler/RM keep connection and updates.

```protobuf
message AllocationRequest {
  // New allocation requests or replace existing allocation request (if allocationID is same)
  repeated AllocationAsk asks = 1;

  // Allocations can be released.
  AllocationReleasesRequest releases = 2;

  // ID of RM, this will be used to identify which RM of the request comes from.
  string rmID = 3;

  // Existing allocations to be added.
  repeated Allocation allocations = 4;
}

message ApplicationRequest {
  // RM should explicitly add application when allocation request also explictly belongs to application.
  // This is optional if allocation request doesn't belong to a application. (Independent allocation)
  repeated AddApplicationRequest new = 1;

  // RM can also remove applications, all allocation/allocation requests associated with the application will be removed
  repeated RemoveApplicationRequest remove = 2;

  // ID of RM, this will be used to identify which RM of the request comes from.
  string rmID = 3;
}

message NodeRequest {
  // New node can be scheduled. If a node is notified to be "unscheduable", it needs to be part of this field as well.
  repeated NodeInfo nodes = 1;

  // ID of RM, this will be used to identify which RM of the request comes from.
  string rmID = 2;
}

message AllocationResponse {
  // New allocations
  repeated Allocation new = 1;

  // Released allocations, this could be either ack from scheduler when RM asks to terminate some allocations.
  // Or it could be decision made by scheduler (such as preemption or timeout).
  repeated AllocationRelease released = 2;

  // Released allocation asks(placeholder), when the placeholder allocation times out
  repeated AllocationAskRelease releasedAsks = 3;

  // Rejected allocation requests
  repeated RejectedAllocationAsk rejected = 4;

  // Rejected allocations
  repeated RejectedAllocation rejectedAllocations = 5;
}

message ApplicationResponse {
  // Rejected Applications
  repeated RejectedApplication rejected = 1;

  // Accepted Applications
  repeated AcceptedApplication accepted = 2;

  // Updated Applications
  repeated UpdatedApplication updated = 3;
}

message NodeResponse {
  // Rejected Node Registrations
  repeated RejectedNode rejected = 1;

  // Accepted Node Registrations
  repeated AcceptedNode accepted = 2;
}

message UpdatedApplication {
  // The application ID that was updated
  string applicationID = 1;
  // State of the application
  string state = 2;
  // Timestamp of the state transition
  int64 stateTransitionTimestamp = 3;
  // Detailed message
  string message = 4;
}

message RejectedApplication {
  // The application ID that was rejected
  string applicationID = 1;
  // A human-readable reason message
  string reason = 2;
}

message AcceptedApplication {
  // The application ID that was accepted
  string applicationID = 1;
}

message RejectedNode {
  // The node ID that was rejected
  string nodeID = 1;
  // A human-readable reason message
  string reason = 2;
}

message AcceptedNode {
  // The node ID that was accepted
  string nodeID = 1;
}
```

#### Ask for more resources

Lifecycle of AllocationAsk:

```
                           Rejected by Scheduler
             +-------------------------------------------+
             |                                           |
             |                                           v
     +-------+---+ Asked  +-----------+Scheduler or,+-----------+
     |Initial    +------->|Pending    |+----+----+->|Rejected   |
     +-----------+By RM   +-+---------+ Asked by RM +-----------+
                                +
                                |
                                v
                          +-----------+
                          |Allocated  |
                          +-----------+
```

Lifecycle of Allocations:

```
         +--Allocated by
         v    Scheduler
 +-----------+        +------------+
 |Allocated  |+------ |Completed   |
 +---+-------+ Stoppe +------------+
     |         by RM
     |                +------------+
     +--------------->|Preempted   |
     +  Preempted by  +------------+
     |    Scheduler
     |
     |
     |                +------------+
     +--------------->|Expired     |
         Timeout      +------------+
        (Part of Allocation
           ask)
```

Common fields for allocation:

```protobuf

// A sparse map of resource to Quantity.
message Resource {
  map<string, Quantity> resources = 1;
}

// Quantity includes a single int64 value
message Quantity {
  int64 value = 1;
}
```

Allocation ask:

```protobuf
message AllocationAsk {
  // Allocation key is used by both of scheduler and RM to track allocations.
  // It doesn't have to be same as RM's internal allocation id (such as Pod name of K8s or ContainerID of YARN).
  // Allocations from the same AllocationAsk which are returned to the RM at the same time will have the same allocationKey.
  // The request is considered an update of the existing AllocationAsk if an AllocationAsk with the same allocationKey
  // already exists.
  string allocationKey = 1;
  // The application ID this allocation ask belongs to
  string applicationID = 2;
  // The partition the application belongs to
  string partitionName = 3;
  // The amount of resources per ask
  Resource resourceAsk = 4;
  // Maximum number of allocations
  int32 maxAllocations = 5;
  // Priority of ask
  int32 priority = 6;
  // Execution timeout: How long this allocation will be terminated (by scheduler)
  // once allocated by scheduler, 0 or negative value means never expire.
  int64 executionTimeoutMilliSeconds = 7;
  // A set of tags for this spscific AllocationAsk. Allocation level tags are used in placing this specific
  // ask on nodes in the cluster. These tags are used in the PlacementConstraints.
  // These tags are optional.
  map<string, string> tags = 8;
  // The name of the TaskGroup this ask belongs to
  string taskGroupName = 9;
  // Is this a placeholder ask (true) or a real ask (false), defaults to false
  // ignored if the taskGroupName is not set
  bool placeholder = 10;
  // Is this ask the originator of the application?
  bool Originator = 11;
  // The preemption policy for this ask
  PreemptionPolicy preemptionPolicy = 12;
}
```

Preemption policy:

```protobuf
message PreemptionPolicy {
  // Opt-out from preemption
  bool allowPreemptSelf = 1;
  // Allow preemption of other tasks with same or lower priority
  bool allowPreemptOther = 2;
}
```

Application requests:

```protobuf
message AddApplicationRequest {
  // The ID of the application, must be unique
  string applicationID = 1;
  // The queue this application is requesting. The scheduler will place the application into a
  // queue according to policy, taking into account the requested queue as per the policy.
  string queueName = 2;
  // The partition the application belongs to
  string partitionName = 3;
  // The user group information of the application owner
  UserGroupInformation ugi = 4;
  // A set of tags for the application. These tags provide application level generic inforamtion.
  // The tags are optional and are used in placing an appliction or scheduling.
  // Application tags are not considered when processing AllocationAsks.
  map<string, string> tags = 5;
  // Execution timeout: How long this application can be in a running state
  // 0 or negative value means never expire.
  int64 executionTimeoutMilliSeconds = 6;
  // The total amount of resources gang placeholders will request
  Resource placeholderAsk = 7;
  // Gang scheduling style can be hard (the application will fail after placeholder timeout)
  // or soft (after the timeout the application will be scheduled as a normal application)
  string gangSchedulingStyle = 8;
}

message RemoveApplicationRequest {
  // The ID of the application to remove
  string applicationID = 1;
  // The partition the application belongs to
  string partitionName = 2;
}
```

User information:
The user that owns the application. Group information can be empty. If the group information is empty the groups will be resolved by the scheduler when needed.
```protobuf
message UserGroupInformation {
  // the user name
  string user = 1;
  // the list of groups of the user, can be empty
  repeated string groups = 2;
}
```

### Allocation of resources

The Allocation message is used in two cases:
1. A recovered allocation send from the RM to the scheduler
2. A newly created allocation from the scheduler.

```protobuf
message Allocation {
  // AllocationKey from AllocationAsk
  string allocationKey = 1;
  // Allocation tags from AllocationAsk
  map<string, string> allocationTags = 2;
  
  // Resource for each allocation
  Resource resourcePerAlloc = 5;
  // Priority of ask
  int32 priority = 6;
  // Node which the allocation belongs to
  string nodeID = 8;
  
  // The ID of the application
  string applicationID = 9;
  // Partition of the allocation
  string partitionName = 10;
  // The name of the TaskGroup this allocation belongs to
  string taskGroupName = 11;
  // Is this a placeholder allocation (true) or a real allocation (false), defaults to false
  // ignored if the taskGroupName is not set
  bool placeholder = 12;
  // AllocationID of the allocation
  string allocationID = 13;
  // Whether this allocation was the originator of this app
  bool originator = 14;
  // The preemption policy for this allocation
  PreemptionPolicy preemptionPolicy = 15;
  
  reserved 7;
  reserved "queueName";
  reserved 3;
  reserved "UUID";
}
```

#### Release previously allocated resources

```protobuf
message AllocationReleasesRequest {
  // The allocations to release
  repeated AllocationRelease allocationsToRelease = 1;
  // The asks to release
  repeated AllocationAskRelease allocationAsksToRelease = 2;
}

enum TerminationType {
    UNKNOWN_TERMINATION_TYPE = 0;//TerminationType not set
    STOPPED_BY_RM = 1;          // Stopped or killed by ResourceManager (created by RM)
    TIMEOUT = 2;                // Timed out based on the executionTimeoutMilliSeconds (created by core)
    PREEMPTED_BY_SCHEDULER = 3; // Preempted allocation by scheduler (created by core)
    PLACEHOLDER_REPLACED = 4;   // Placeholder allocation replaced by real allocation (created by core)
}

// Release allocation: this is a bidirectional message. The Terminationtype defines the origin, or creator,
// as per the comment. The confirmation or response from the receiver is the same message with the same
// termination type set.
message AllocationRelease {

  // The name of the partition the allocation belongs to
  string partitionName = 1;
  // The application the allocation belongs to
  string applicationID = 2;
  // Termination type of the released allocation
  TerminationType terminationType = 4;
  // human-readable message
  string message = 5;
  // AllocationKey from AllocationAsk
  string allocationKey = 6;
  // AllocationID of the allocation to release, if not set all allocations are released for
  // the applicationID
  string allocationID = 7;
  
  reserved 3;
  reserved "UUID";
}

// Release ask
message AllocationAskRelease {
  // Which partition to release the ask from, required.
  string partitionName = 1;
  // optional, when this is set, filter allocation key by application id.
  // when application id is set and allocationKey is not set, release all allocations key under the application id.
  string applicationID = 2;
  // optional, when this is set, only release allocation ask by specified
  string allocationKey = 3;
  // Termination type of the released allocation ask
  TerminationType terminationType = 4;
  // For human-readable message
  string message = 5;
}
```

#### Schedulable nodes registration and updates

State transition of node:

```
   +-----------+          +--------+            +-------+
   |SCHEDULABLE|+-------->|DRAINING|+---------->|REMOVED|
   +-----------+          +--------+            +-------+
         ^       Asked by      +     Aasked by
         |      RM to DRAIN    |     RM to REMOVE
         |                     |
         +---------------------+
              Asked by RM to
              SCHEDULE again
```

See protocol below:

During new node registration with the scheduler, request will be rejected if the node exist already.
While updating registered node with the scheduler, request will fail if the node doesn't exist.
```protobuf
message NodeInfo {
  // Action from RM
  enum ActionFromRM {

    //ActionFromRM not set
    UNKNOWN_ACTION_FROM_RM = 0;

    // Create Node as initially schedulable.
    CREATE = 1;

    // Update node resources, attributes.
    UPDATE = 2;

    // Do not allocate new allocations on the node.
    DRAIN_NODE = 3;

    // Decomission node, it will immediately stop allocations on the node and
    // remove the node from schedulable lists.
    DECOMISSION = 4;

    // From Draining state to SCHEDULABLE state.
    // If node is not in draining state, error will be thrown
    DRAIN_TO_SCHEDULABLE = 5;

    // Create Node as initially draining (i.e. unschedulable). Before scheduling can proceed,
    // DRAIN_TO_SCHEDULABLE must be called.
    CREATE_DRAIN = 6;
  }

  // ID of node, the node must exist to be updated
  string nodeID = 1;

  // Action to perform by the scheduler
  ActionFromRM action = 2;

  // New attributes of node, which will replace previously reported attribute.
  map<string, string> attributes = 3;

  // new schedulable resource, scheduler may preempt allocations on the
  // node or schedule more allocations accordingly.
  Resource schedulableResource = 4;

  // when the scheduler is co-exist with some other schedulers, some node
  // resources might be occupied (allocated) by other schedulers.
  Resource occupiedResource = 5;

  // Allocated resources, this will be added when node registered to RM (recovery)
  repeated Allocation existingAllocations = 6;
}
```

#### Feedback from Scheduler

The following is the feedback produced from the scheduler to the RM:

Rejected allocation ask:

```protobuf
message RejectedAllocationAsk {
  // the ID of the allocation ask
  string allocationKey = 1;
  // The ID of the application
  string applicationID = 2;
  // A human-readable reason message
  string reason = 3;
}
```

Rejected allocation:

```protobuf
message RejectedAllocation {
  // the ID of the allocation
  string allocationKey = 1;
  // The ID of the application
  string applicationID = 2;
  // A human-readable reason message
  string reason = 3;
}
```

### Following are constant of spec

Scheduler Interface attributes start with the si prefix. Such constants are for example known attribute names for nodes and applications.

```constants
// Constants for node attributes
const (
	ARCH                = "si/arch"
	HostName            = "si/hostname"
	RackName            = "si/rackname"
	OS                  = "si/os"
	InstanceType        = "si/instance-type"
	FailureDomainZone   = "si/zone"
	FailureDomainRegion = "si/region"
	LocalImages         = "si/local-images"
	NodePartition       = "si/node-partition"
)

// Constants for allocation attributes
const (
	ApplicationID  = "si/application-id"
	ContainerImage = "si/container-image"
	ContainerPorts = "si/container-ports"
)
```

Allocation tags are key-value pairs, where the key should contain a domain, and optionally a group part.
These parts should precede the name of the key (and should be in that order) and separated by a "/" character.
Example allocation key: `kubernetes.io/meta/namespace`.

```constants
// Constants for allocation tags
const (
	// Domains
	DomainK8s      = "kubernetes.io/"
	DomainYuniKorn = "yunikorn.apache.org/"

	// Groups
	GroupMeta       = "meta/"
	GroupLabel      = "label/"
	GroupAnnotation = "annotation/"

	// Keys
	KeyPodName         = "podName"
	KeyNamespace       = "namespace"
	KeyRequiredNode    = "requiredNode"

	// Pods
	CreationTime    = "creationTime"
)
```

Miscellaneous constants for resources and other values.

```constants
// Constants for Core and Shim
const (
	Memory                            = "memory"
	CPU                               = "vcore"
	AppTagNamespaceResourceQuota      = "namespace.resourcequota"
	AppTagNamespaceResourceGuaranteed = "namespace.resourceguaranteed"
	AppTagStateAwareDisable           = "application.stateaware.disable"
	AppTagCreateForce                 = "application.create.force"
	NodeReadyAttribute                = "ready"
)
```

### Scheduler plugin

SchedulerPlugin is a way to extend scheduler capabilities. Scheduler shim can implement such plugin and register itself to
yunikorn-core, so plugged function can be invoked in the scheduler core.

```protobuf
message PredicatesArgs {
    // allocation key identifies a container, the predicates function is going to check
    // if this container is eligible to be placed ont to a node.
    string allocationKey = 1;
    // the node ID the container is assigned to.
    string nodeID = 2;
    // run the predicates for alloactions (true) or reservations (false)
    bool allocate = 3;
}

message PreemptionPredicatesArgs {
    // the allocation key of the container to check
    string allocationKey = 1;
    // the node ID the container should be attempted to be scheduled on
    string nodeID = 2;
    // a list of existing allocations that should be tentatively removed before checking
    repeated string preemptAllocationKeys = 3;
    // index of last allocation in starting attempt (first attempt should be 0..startIndex)
    int32 startIndex = 4;
}

message PreemptionPredicatesResponse {
    // whether or not container will schedule on the node
    bool success = 1;
    // index of last allocation which was removed before success (ignored during failure)
    int32 index = 2;
}

message UpdateContainerSchedulingStateRequest {
   // container scheduling states
   enum SchedulingState {
     //SchedulingState not set
     UNKNOWN_SCHEDULING_STATE = 0;
     // the container is being skipped by the scheduler
     SKIPPED = 1;
     // the container is scheduled and it has been assigned to a node
     SCHEDULED = 2;
     // the container is reserved on some node, but not yet assigned
     RESERVED = 3;
     // scheduler has visited all candidate nodes for this container
     // but non of them could satisfy this container's requirement
     FAILED = 4;
   }

   // application ID
   string applicationID = 1;

   // allocation key used to identify a container.
   string allocationKey = 2;

   // container scheduling state
   SchedulingState state = 3;

   // an optional plain message to explain why it is in such state
   string reason = 4;
}

message UpdateConfigurationRequest {
  // RM ID to update
  string rmID = 2;

  // PolicyGroup to update
  string policyGroup = 3;

  // New configuration to update
  string config = 4;

  // Additional configuration key/value pairs for configuration not related to the policyGroup.
  map<string, string> extraConfig = 5;

  reserved 1;
  reserved "configs";
}
```

#### Event Plugin

The Event Cache is a SchedulerPlugin that exposes events about scheduler objects aiming to help the end user to
see these events from the shim side. An event is sent to the shim through the callback as an `EventRecord`.
An `EventRecord` consists of the following fields:

```protobuf
message EventRecord {
   enum Type {
      //EventRecord Type not set
      UNKNOWN_EVENTRECORD_TYPE = 0;
      REQUEST = 1;
      APP = 2;
      NODE = 3;
      QUEUE = 4;
   }

   enum ChangeType {
      NONE = 0;
      SET = 1;
      ADD = 2;
      REMOVE = 3;
   }

   enum ChangeDetail {
     DETAILS_NONE       = 0;

     REQUEST_CANCEL     = 100;  // Request cancelled by the RM
     REQUEST_ALLOC      = 101;  // Request allocated
     REQUEST_TIMEOUT    = 102;  // Request cancelled due to timeout

     APP_ALLOC          = 200;  // Allocation changed
     APP_REQUEST        = 201;  // Request changed
     APP_REJECT         = 202;  // Application rejected on create
     APP_NEW            = 203;  // Application added with state new
     APP_ACCEPTED       = 204;  // State change to accepted 
     APP_STARTING       = 205;  // State change to starting
     APP_RUNNING        = 206;  // State change to running
     APP_COMPLETING     = 207;  // State change to completing
     APP_COMPLETED      = 208;  // State change to completed
     APP_FAILING        = 209;  // State change to failing
     APP_FAILED         = 210;  // State change to failed
     APP_RESUMING       = 211;  // State change to resuming
     APP_EXPIRED        = 212;  // State change to expired

     NODE_DECOMISSION   = 300;  // Node removal
     NODE_READY         = 301;  // Node ready state change
     NODE_SCHEDULABLE   = 302;  // Node schedulable state change (cordon)
     NODE_ALLOC         = 303;  // Allocation changed
     NODE_CAPACITY      = 304;  // Capacity changed
     NODE_OCCUPIED      = 305;  // Occupied resource changed
     NODE_RESERVATION   = 306;  // Reservation/unreservation occurred

     QUEUE_CONFIG       = 400;  // Managed queue update or removal
     QUEUE_DYNAMIC      = 401;  // Dynamic queue update or removal
     QUEUE_TYPE         = 402;  // Queue type change
     QUEUE_MAX          = 403;  // Max resource changed
     QUEUE_GUARANTEED   = 404;  // Guaranteed resource changed
     QUEUE_APP          = 405;  // Application changed
     QUEUE_ALLOC        = 406;  // Allocation changed

     ALLOC_CANCEL       = 500;  // Allocation cancelled by the RM
     ALLOC_PREEMPT      = 501;  // Allocation preempted by the core
     ALLOC_TIMEOUT      = 502;  // Allocation cancelled due to timeout
     ALLOC_REPLACED     = 503;  // Allocation replacement (placeholder)
     ALLOC_NODEREMOVED  = 504;  // Allocation cancelled, node removal
   }

   // the type of the object associated with the event
   Type type = 1;
   // ID of the object associated with the event
   string objectID = 2;
   // the detailed message as string
   string message = 5;
   // timestamp of the event
   int64 timestampNano = 6;
   // the type of the change
   ChangeType eventChangeType = 7;
   // details about the change
   ChangeDetail eventChangeDetail = 8;
   // the secondary object in the event (eg. allocation ID, request ID)
   string referenceID = 9;
   // the resource value if the change involves setting/modifying a resource
   Resource resource = 10;

   reserved 3;
   reserved "groupID";
   reserved 4;
   reserved "reason";
}
```
