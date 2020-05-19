// **** DO NOT EDIT
// **** This code is generated by the build process.
// **** DO NOT EDIT
package common

// Constants for node attributes
const (
	ARCH                = "si.io/arch"
	HostName            = "si.io/hostname"
	RackName            = "si.io/rackname"
	OS                  = "si.io/os"
	InstanceType        = "si.io/instance-type"
	FailureDomainZone   = "si.io/zone"
	FailureDomainRegion = "si.io/region"
	LocalImages         = "si.io/local-images"
	NodePartition       = "si.io/node-partition"
)

// Constants for allocation attributes
const (
	ApplicationID  = "si.io/application-id"
	ContainerImage = "si.io/container-image"
	ContainerPorts = "si.io/container-ports"
)
// Cluster
const DefaultNodeAttributeHostNameKey = "si.io/hostname"
const DefaultNodeAttributeRackNameKey = "si.io/rackname"

// Application
const LabelApp = "app"
const LabelApplicationID = "applicationId"
const LabelQueueName = "queue"

// Resource
const Memory = "memory"
const CPU = "vcore"

// Spark
const SparkLabelAppID = "spark-app-selector"
const SparkLabelRole = "spark-role"
const SparkLabelRoleDriver = "driver"