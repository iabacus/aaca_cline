//go:build !windows

package cli

import "syscall"

func killProcess(pid int) error {
	return syscall.Kill(pid, syscall.SIGTERM)
}
