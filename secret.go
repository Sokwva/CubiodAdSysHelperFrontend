package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
)

const SeCrETMaIN = "321"
const SeCrETBaCkUP = "123"

func getAESKey() (bool, *APIInitSecKeyRet) {
	req, err := http.Get(APIEndpoint + APIInitSecKeyPath)
	if err != nil {
		panic(err)
	}
	var resp APIInitSecKeyRet
	rawResp, err := ioutil.ReadAll(req.Body)
	if err != nil {
		return false, nil
	}
	err = json.Unmarshal(rawResp, &resp)
	if err != nil {
		return false, nil
	}
	defer req.Body.Close()
	return true, &resp
}
