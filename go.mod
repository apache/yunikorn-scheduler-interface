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
	golang.org/x/net v0.8.0
	google.golang.org/grpc v1.23.1
	google.golang.org/protobuf v1.26.0-rc.1
)

replace (
	github.com/golang/protobuf => github.com/golang/protobuf v1.2.0
	golang.org/x/crypto => golang.org/x/crypto v0.7.0
	golang.org/x/lint => golang.org/x/lint v0.0.0-20210508222113-6edffad5e616
	golang.org/x/net => golang.org/x/net v0.8.0
	golang.org/x/sys => golang.org/x/sys v0.6.0
	golang.org/x/text => golang.org/x/text v0.8.0
	golang.org/x/tools => golang.org/x/tools v0.7.0
)
