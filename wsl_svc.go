package main

import (
	"bufio"
	"io"
	"log"
	"os"
	"os/exec"
	"syscall"
	"time"

	"golang.org/x/text/encoding/unicode"
	"golang.org/x/text/transform"
)

func wslCommand(args ...string) (cmd *exec.Cmd, stdout io.Reader, stderr io.Reader, err error) {
	cmd = exec.Command("wsl.exe", args...)
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	if stdout, err = cmd.StdoutPipe(); err != nil {
		return
	}
	if stderr, err = cmd.StderrPipe(); err != nil {
		return
	}
	win16le := unicode.UTF16(unicode.LittleEndian, unicode.IgnoreBOM)
	stdout = transform.NewReader(stdout, unicode.BOMOverride(win16le.NewDecoder()))
	stderr = transform.NewReader(stderr, unicode.BOMOverride(win16le.NewDecoder()))
	err = cmd.Start()
	return
}

func listRunning() (list []string, err error) {
	var cmd *exec.Cmd
	var stdout io.Reader
	var stderr io.Reader
	cmd, stdout, stderr, err = wslCommand("-l", "--running", "--quiet")
	if err != nil {
		return
	}
	go io.Copy(os.Stderr, stderr)
	sc := bufio.NewScanner(stdout)
	for sc.Scan() {
		t := sc.Text()
		if t != "" {
			list = append(list, t)
		}
	}
	err = cmd.Wait()
	return
}

const initCommand = `pgrep -x -o systemd || ` +
	`/usr/bin/unshare --fork --pid --mount-proc /lib/systemd/systemd --system-unit=multi-user.target`

func run(dist string) error {
	cmd, stdout, stderr, err := wslCommand("-d", dist, "-u", "root", "/bin/bash", "-c", initCommand)
	if err != nil {
		return err
	}
	go io.Copy(os.Stdout, stdout)
	go io.Copy(os.Stderr, stderr)
	return cmd.Wait()
}

func main() {
	dist := "Arch"
	if len(os.Args) >= 2 {
		dist = os.Args[1]
	}

	doRun := true
	for {
		if doRun {
			log.Printf("Launching")
			err := run(dist)
			if err != nil {
				log.Printf("Error: %s", err)
			}
		}
		time.Sleep(5 * time.Second)
		rn, err := listRunning()
		if err != nil {
			log.Printf("Error listing: %s", err)
		}
		doRun = false
		for _, v := range rn {
			if v == dist {
				doRun = true
			}
		}
		if !doRun {
			log.Printf("WSL Dist not running")
		}
	}
}
