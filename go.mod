//
// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

module github.com/apache/yunikorn-scheduler-interface

go 1.15

require (
	github.com/golang/protobuf v1.2.0
	golang.org/x/net v0.0.0-20220812174116-3211cb980234
	golang.org/x/sync v0.0.0-20220722155255-886fb9371eb4 // indirect
	golang.org/x/sys v0.0.0-20220817070843-5a390386f1f2 // indirect
	google.golang.org/grpc v1.23.1
	google.golang.org/protobuf v1.26.0-rc.1
)

replace github.com/golang/protobuf => github.com/golang/protobuf v1.2.0
