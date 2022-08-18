// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//     http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Code generated by make build. DO NOT EDIT

package common

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
	KeyAllowPreemption = "allowPreemption"

	// Pods
	CreationTime = "creationTime"
)

// Constants for Core and Shim
const (
	Memory                       = "memory"
	CPU                          = "vcore"
	AppTagNamespaceResourceQuota = "namespace.resourcequota"
	AppTagStateAwareDisable      = "application.stateaware.disable"
	NodeReadyAttribute           = "ready"
)
