package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"syscall"

	"github.com/go-toast/toast"
	"github.com/mitchellh/go-ps"
)

// %temp%\CubiodAdSys\
func getWorkDir() string {
	tempdir := os.Getenv("TEMP")
	workdir := ""
	if tempdir != "" {
		workdir = tempdir + WORKDIRNAME
	}
	return strings.TrimSpace(workdir)
}

func killProcesses(schedKillProList []string) {
	for _, v := range schedKillProList {
		c := exec.Command("taskkill.exe", "/f", "/im", v)
		c.Start()
	}
}

func msgBox(msg string) {
	c := exec.Command("msg", "*", msg)
	c.Start()
}

func popNotification(title string, msg string) {
	notification := toast.Notification{
		AppID:   "Microsoft.Windows.Shell.RunDialog",
		Title:   title,
		Message: msg,
		Icon:    "http://192.168.1.2/static/logo.png",
		Actions: []toast.Action{
			{Type: "protocol", Label: "按钮1", Arguments: "http://192.168.1.2/"},
		},
	}
	err := notification.Push()
	if err != nil {
		log.Fatalln(err)
	}
}

func getProcessList() ([]ps.Process, error) {
	procList, err := ps.Processes()
	if err != nil {
		panic(err)
	}
	return procList, nil
}

func judgehasTargetProc(lst []ps.Process, name string) bool {
	for _, v := range lst {
		if v.Executable() == name {
			return true
		}
	}
	return false
}

func GetSystemVersion() string {
	version, err := syscall.GetVersion()
	if err != nil {
		return ""
	}
	return fmt.Sprintf("%d.%d (%d)", byte(version), uint8(version>>8), version>>16)
}
