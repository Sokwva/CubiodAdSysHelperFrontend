package main

//AdHelperFronter.exe
//抄抄抄

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"os/user"
)

const WORKDIRNAME = "\\CubiodAdSys\\"

var secret string = "Cubiod123"

func main() {
	log.Println("Init")
	file := getWorkDir() + `\Core\Main.log`
	logFile, err := os.OpenFile(file, os.O_RDWR|os.O_CREATE|os.O_APPEND, 0766)
	if err != nil {
		panic(err)
	}
	log.SetOutput(logFile) // 将文件设置为log输出的文件
	log.SetPrefix("[AdHelperFronter]")
	log.SetFlags(log.LstdFlags | log.Lshortfile | log.Ltime)

	log.Println("Started")
	var softwareList APIDataSoftListResp
	log.Println("Get SoftwareList by Server.")
	resp, err := http.Get(APIEndpoint + APISoftList)
	if err != nil {
		panic(err)
	}
	log.Println("parse Api resturn")
	rawResp, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		panic(err)
	}
	log.Println("parse Api content")
	json.Unmarshal(rawResp, &softwareList)
	log.Println(softwareList)
	for _, v := range softwareList.Data {
		err := fetchPkg(v)
		if err == nil {
			runPkg(v)
		}
	}
}

func runPkg(v APISoftwareListItem) {
	switch v.InstallType {
	case "system":
		log.Println("execute", v.PackageMain, "by system")
		privilegeExec(getWorkDir(), v.PackageMain)
		fmt.Println(v.PackageMain, v.InstallType)
	case "user":
		log.Println("execute", v.PackageMain, "by user")
		unprivilegeExec(getWorkDir() + v.PackageMain)
		fmt.Println(v.PackageMain, v.InstallType)
	}
}

func fetchPkg(v APISoftwareListItem) error {
	log.Println("fetch pkg ", v.PackageMain)
	headerResp, err := http.Head(StoreSvcEndpoint + v.PackageMain)
	if err != nil {
		return err
	}
	fileLeng := int(headerResp.ContentLength)
	req, err := http.NewRequest("GET", StoreSvcEndpoint+v.PackageMain, nil)
	if err != nil {
		return err
	}
	req.Header.Set("Range", fmt.Sprintf("bytes=%d-%d", 0, fileLeng))
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	fd, err := os.OpenFile(getWorkDir()+v.PackageMain, os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		return err
	}
	buf := make([]byte, 16*1024)
	_, err = io.CopyBuffer(fd, resp.Body, buf)
	log.Println("fetched", v.PackageMain)
	if err != nil {
		return err
	}
	defer fd.Close()
	return nil
}

func privilegeExec(execPath string, execName string) error {
	if secret == "" {
		return nil
	} else {
		workdir := getWorkDir()
		lsrunasePath := workdir + `Core\lsrunase.exe`
		currentUser, _ := user.Current()
		log.Println(GetSystemVersion(), "wait to judge windows version")
		if GetSystemVersion() == "6.2 (9200)" {
			log.Println("Windows 10")
			if err := isNeedPromote(); err != nil {
				log.Println("under windows 10 after require uac premote to exec package;username: ", currentUser)
				return win10PromotionAction(execPath, execName)
			} else {
				log.Println("under windows 10 but no require uac premote to exec package;username: ", currentUser)
				c := exec.Command(execPath + execName)
				err := c.Start()
				log.Println(err)
				return err
			}
		}
		fmt.Println("Windows 7")
		c := exec.Command(lsrunasePath, "/user:Administrator", "/password:"+SeCrETBaCkUP, "/domain:", "/runpath:"+execPath, "/command:cmd /C start "+execName)
		err := c.Start()
		log.Println(err)
		return err
	}
}

func unprivilegeExec(execPath string) error {
	if secret == "" {
		return nil
	} else {
		c := exec.Command(execPath)
		return c.Start()
	}
}

func isNeedPromote() error {
	log.Println("judge if need premote")
	_, err := os.Open("\\\\.\\PHYSICALDRIVE0")
	if err != nil {
		log.Println("got premotion need require result: require promote")
	} else {
		log.Println("got premotion need require result: no require promote")
	}
	return err
}

func win10PromotionAction(execPath string, execName string) error {
	workdir := getWorkDir()
	lsrunasePath := workdir + `Core\lsrunase.exe`

	log.Println("preset vbs promote loader")
	rawVBS := `Set UAC = CreateObject("Shell.Application") 
UAC.ShellExecute "` + lsrunasePath + `", "/user:Administrator /password:` + SeCrETBaCkUP + ` /domain: /runpath:` + execPath + ` /command:"" cmd /C start "` + execName + `, "", "runas", 1 
				`
	fd, err := os.OpenFile(workdir+`Core\getPromote.vbs`, os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		return err
	}
	log.Println("create vbs promote loader file")
	_, err = io.WriteString(fd, rawVBS)
	if err != nil {
		return err
	}
	log.Println("preset vbs promote preloader")
	rawCmd := `wscript.exe ` + workdir + `Core\getPromote.vbs` + `
exit`
	fd2, err := os.OpenFile(workdir+`Core\startGetPromote.bat`, os.O_CREATE|os.O_WRONLY, 0666)
	if err != nil {
		return err
	}
	log.Println("create vbs promote preloader")
	_, err = io.WriteString(fd2, rawCmd)
	if err != nil {
		return err
	}
	log.Println("ready to execute vbs promote preloader")
	c := exec.Command(`cmd`, `/C start `+workdir+`Core\startGetPromote.bat`)
	defer fd.Close()
	defer fd2.Close()
	log.Println("cleaning")
	return c.Start()
}
