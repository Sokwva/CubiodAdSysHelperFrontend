package main

type APIInitSecKeyRet struct {
	Code     int    `json:"code"`
	Response string `json:"response"`
}

type APISoftwareListItem struct {
	Name        string
	PackageMain string
	PackType    string
	InstallType string
	ProcessName string `toml:"procname"`
}

type APIDataSoftListResp struct {
	Code uint
	Data []APISoftwareListItem
}
