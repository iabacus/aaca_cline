//go:build windows

package cli

import "syscall"

func killProcess(pid int) error {
	proc, err := syscall.OpenProcess(syscall.PROCESS_TERMINATE, false, uint32(pid))
	if err != nil {
		return err
	}
	defer syscall.CloseHandle(proc)
	return syscall.TerminateProcess(proc, 1)
}
