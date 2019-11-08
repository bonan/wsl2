all: wsl_svc.exe

wsl_svc.exe: wsl_svc.go
	env GOOS=windows GOARCH=amd64 go build -ldflags "-s -w -H windowsgui" -o wsl_svc.exe .
