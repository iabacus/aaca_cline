//go:build !windows

package global

import (
	"os/exec"
	"syscall"
)

func setSysProcAttr(cmd *exec.Cmd) {
	cmd.SysProcAttr = &syscall.SysProcAttr{
		Setpgid: true,
	}
}

func killProcess(pid int) error {
	return syscall.Kill(pid, syscall.SIGTERM)
}
