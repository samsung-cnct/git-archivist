/*
Copyright 2017 Samsung SDSA CNCT

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"strings"
	"time"

	"github.com/golang/glog"
)

var (
	resyncPeriod = 30 * time.Second
)

// GA Server
type gaServer struct {
	// Command line / environment supplied configuration values
	cfg    *config
	stopCh chan struct{}
}

func newGAServer(cfg *config) *gaServer {
	return &gaServer{
		stopCh: make(chan struct{}),
		cfg:    cfg,
	}
}

func (as *gaServer) checkForUpdates() {
	glog.V(2).Infof("checking for updates at: %v", time.Now())

	cmdOutBytes, err := Execute(GitCmd, []string{GitStatus, GitArgShort, GitArgNoUntracked})
	if err != nil {
		glog.Warningf("error: executing %s %s %s %s, returned: %v",
			GitCmd, GitStatus, GitArgShort, GitArgNoUntracked, err)
		return
	}
	cmdOutString := strings.Split(string(cmdOutBytes), "\n")
	if len(cmdOutString) > 0 {
		glog.V(2).Infof("command output: %v", cmdOutString)
	}
}

func (as *gaServer) run() {
	glog.V(2).Infof("starting run at: %v", time.Now())

	go Until(as.checkForUpdates, time.Duration(*as.cfg.frequency)*time.Second, as.stopCh)
	for {
		time.Sleep(60 * time.Second)
	}
}
