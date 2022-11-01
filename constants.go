package main

const APISvrHost = "192.168.1.2"
const APISvrPort = "80"
const APISvrPrefix = "/adsys/api"

const APIEndpoint = "http://" + APISvrHost + ":" + APISvrPort + APISvrPrefix

const APIInitSecKeyPath = "/auth/countInit"
const APISoftList = "/data/list"

const StoreSvcHost = "192.168.1.2"
const StoreSvrPath = "/static/adsys/"
const StoreSvcEndpoint = "http://" + StoreSvcHost + StoreSvrPath
