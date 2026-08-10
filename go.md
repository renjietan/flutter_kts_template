package utils

import (
	"fmt"
	"log"
	"os"
	"strings"
	"sync"
	"unsafe"

	"golang.org/x/sys/windows"
	"golang.org/x/sys/windows/registry"
)

// ---- DLL ----
var (
	winusbDLL = windows.NewLazyDLL("winusb.dll")

	procWinUsb_Initialize             = winusbDLL.NewProc("WinUsb_Initialize")
	procWinUsb_QueryInterfaceSettings = winusbDLL.NewProc("WinUsb_QueryInterfaceSettings")
	procWinUsb_QueryPipe              = winusbDLL.NewProc("WinUsb_QueryPipe")
	procWinUsb_WritePipe              = winusbDLL.NewProc("WinUsb_WritePipe")
	procWinUsb_ReadPipe               = winusbDLL.NewProc("WinUsb_ReadPipe")
	procWinUsb_Free                   = winusbDLL.NewProc("WinUsb_Free")
	procWinUsb_SetPipePolicy          = winusbDLL.NewProc("WinUsb_SetPipePolicy")
	procWinUsb_FlushPipe              = winusbDLL.NewProc("WinUsb_FlushPipe")
)

// ---- 常量 ----
const (
	PIPE_TRANSFER_TIMEOUT = 0x03
)

// ---- 结构体 ----
type USB_INTERFACE_DESCRIPTOR struct {
	bLength            byte
	bDescriptorType    byte
	bInterfaceNumber   byte
	bAlternateSetting  byte
	bNumEndpoints      byte
	bInterfaceClass    byte
	bInterfaceSubClass byte
	bInterfaceProtocol byte
	iInterface         byte
}

type WINUSB_PIPE_INFORMATION struct {
	PipeType          uint32
	PipeId            byte
	MaximumPacketSize uint16
	Interval          byte
}

// DeviceInfo 设备基本信息
type DeviceInfo struct {
	Path string
	VID  string
	PID  string
}

// Device WinUSB 设备
type Device struct {
	mu        sync.Mutex
	devHandle windows.Handle
	usbHandle uintptr
	EpOut     byte
	EpIn      byte
	Path      string
	VID       string
	PID       string
}

// ---- 从注册表枚举设备 ----
func ListDevices() ([]DeviceInfo, error) {
	usbKey, err := registry.OpenKey(registry.LOCAL_MACHINE,
		`SYSTEM\CurrentControlSet\Enum\USB`,
		registry.ENUMERATE_SUB_KEYS)
	if err != nil {
		return nil, fmt.Errorf("打开USB注册表失败: %w", err)
	}
	defer usbKey.Close()

	vidPidKeys, err := usbKey.ReadSubKeyNames(-1)
	if err != nil {
		return nil, fmt.Errorf("读取USB子键失败: %w", err)
	}

	var devices []DeviceInfo

	for _, vidPidKey := range vidPidKeys {
		instanceKey, err := registry.OpenKey(registry.LOCAL_MACHINE,
			`SYSTEM\CurrentControlSet\Enum\USB\`+vidPidKey,
			registry.ENUMERATE_SUB_KEYS)
		if err != nil {
			continue
		}

		instanceIDs, err := instanceKey.ReadSubKeyNames(-1)
		instanceKey.Close()
		if err != nil {
			continue
		}

		for _, instanceID := range instanceIDs {
			devPath := `SYSTEM\CurrentControlSet\Enum\USB\` + vidPidKey + `\` + instanceID
			devKey, err := registry.OpenKey(registry.LOCAL_MACHINE, devPath, registry.QUERY_VALUE)
			if err != nil {
				continue
			}

			// 只取 Service=WINUSB 的设备
			service, _, err := devKey.GetStringValue("Service")
			devKey.Close()
			if err != nil || !strings.EqualFold(service, "WINUSB") {
				continue
			}

			// 构造设备路径: \\?\USB#VID_xxxx&PID_xxxx&MI_xx#instanceID#{GUID}
			// GUID 从注册表 ClassGUID 读取
			devKey2, err := registry.OpenKey(registry.LOCAL_MACHINE, devPath, registry.QUERY_VALUE)
			if err != nil {
				continue
			}
			classGUID, _, err := devKey2.GetStringValue("ClassGUID")
			devKey2.Close()
			if err != nil {
				continue
			}

			// 去掉 { } 括号
			classGUID = strings.Trim(classGUID, "{}")
			path := fmt.Sprintf(`\\?\USB#%s#%s#{%s}`, vidPidKey, instanceID, classGUID)

			fmt.Printf("尝试路径: %s\n", path)

			if !canOpenAsWinUSB(path) {
				continue
			}

			devices = append(devices, DeviceInfo{
				Path: path,
				VID:  extractField(path, "VID_"),
				PID:  extractField(path, "PID_"),
			})
		}
	}

	return devices, nil
}

// ListDevices 从注册表枚举所有可用的 WinUSB 设备

// canOpenAsWinUSB 验证路径是否可以被 WinUSB 初始化
func canOpenAsWinUSB(path string) bool {
	handle, err := windows.CreateFile(
		windows.StringToUTF16Ptr(path),
		windows.GENERIC_READ|windows.GENERIC_WRITE,
		windows.FILE_SHARE_READ|windows.FILE_SHARE_WRITE,
		nil,
		windows.OPEN_EXISTING,
		windows.FILE_ATTRIBUTE_NORMAL|windows.FILE_FLAG_OVERLAPPED,
		0,
	)
	if err != nil {
		return false
	}
	defer windows.CloseHandle(handle)

	var usbHandle uintptr
	r, _, _ := procWinUsb_Initialize.Call(
		uintptr(handle),
		uintptr(unsafe.Pointer(&usbHandle)),
	)
	if r == 0 {
		return false
	}
	procWinUsb_Free.Call(usbHandle)
	return true
}

// extractField 从路径中提取 VID_ 或 PID_ 后面的4位
func extractField(path, prefix string) string {
	upper := strings.ToUpper(path)
	idx := strings.Index(upper, prefix)
	if idx == -1 {
		return ""
	}
	start := idx + len(prefix)
	if start+4 > len(path) {
		return ""
	}
	return strings.ToUpper(path[start : start+4])
}

// ---- 打开设备 ----

// OpenAuto 自动枚举并打开唯一的 WinUSB 设备
// 只有一个设备时直接打开，多个设备时返回错误
func OpenAuto() (*Device, error) {
	devices, err := ListDevices()
	if err != nil {
		return nil, err
	}

	switch len(devices) {
	case 0:
		return nil, fmt.Errorf("未找到任何 WinUSB 设备")
	case 1:
		log.Printf("找到设备: VID=%s PID=%s\n", devices[0].VID, devices[0].PID)
		return Open(devices[0].Path)
	default:
		var list strings.Builder
		for i, d := range devices {
			list.WriteString(fmt.Sprintf("  [%d] VID=%s PID=%s Path=%s\n", i, d.VID, d.PID, d.Path))
		}
		return nil, fmt.Errorf("检测到多个 WinUSB 设备，请确保只插入一个设备:\n%s", list.String())
	}
}

// Open 通过设备路径打开
func Open(devicePath string) (*Device, error) {
	handle, err := windows.CreateFile(
		windows.StringToUTF16Ptr(devicePath),
		windows.GENERIC_READ|windows.GENERIC_WRITE,
		windows.FILE_SHARE_READ|windows.FILE_SHARE_WRITE,
		nil,
		windows.OPEN_EXISTING,
		windows.FILE_ATTRIBUTE_NORMAL|windows.FILE_FLAG_OVERLAPPED,
		0,
	)
	if err != nil {
		return nil, fmt.Errorf("CreateFile 失败: %w", err)
	}

	var usbHandle uintptr
	r, _, e := procWinUsb_Initialize.Call(
		uintptr(handle),
		uintptr(unsafe.Pointer(&usbHandle)),
	)
	if r == 0 {
		windows.CloseHandle(handle)
		return nil, fmt.Errorf("WinUsb_Initialize 失败: %w", e)
	}

	d := &Device{
		devHandle: handle,
		usbHandle: usbHandle,
		Path:      devicePath,
		VID:       extractField(devicePath, "VID_"),
		PID:       extractField(devicePath, "PID_"),
	}

	if err := d.queryEndpoints(); err != nil {
		d.Close()
		return nil, err
	}

	if err := d.setPipeTimeout(d.EpOut, 5000); err != nil {
		d.Close()
		return nil, err
	}
	if err := d.setPipeTimeout(d.EpIn, 5000); err != nil {
		d.Close()
		return nil, err
	}

	return d, nil
}

// ---- 内部方法 ----

func (d *Device) queryEndpoints() error {
	var ifaceDesc USB_INTERFACE_DESCRIPTOR
	r, _, e := procWinUsb_QueryInterfaceSettings.Call(
		d.usbHandle,
		0,
		uintptr(unsafe.Pointer(&ifaceDesc)),
	)
	if r == 0 {
		return fmt.Errorf("QueryInterfaceSettings 失败: %w", e)
	}

	for i := byte(0); i < ifaceDesc.bNumEndpoints; i++ {
		var pipeInfo WINUSB_PIPE_INFORMATION
		r, _, e = procWinUsb_QueryPipe.Call(
			d.usbHandle,
			0,
			uintptr(i),
			uintptr(unsafe.Pointer(&pipeInfo)),
		)
		if r == 0 {
			return fmt.Errorf("QueryPipe[%d] 失败: %w", i, e)
		}
		if pipeInfo.PipeId&0x80 != 0 {
			d.EpIn = pipeInfo.PipeId
		} else {
			d.EpOut = pipeInfo.PipeId
		}
	}

	if d.EpOut == 0 || d.EpIn == 0 {
		return fmt.Errorf("端点未找到: EpOut=0x%02X EpIn=0x%02X", d.EpOut, d.EpIn)
	}
	return nil
}

func (d *Device) setPipeTimeout(ep byte, timeoutMs uint32) error {
	r, _, e := procWinUsb_SetPipePolicy.Call(
		d.usbHandle,
		uintptr(ep),
		PIPE_TRANSFER_TIMEOUT,
		4,
		uintptr(unsafe.Pointer(&timeoutMs)),
	)
	if r == 0 {
		return fmt.Errorf("SetPipePolicy 失败: %w", e)
	}
	return nil
}

// ---- 公开方法 ----

// Write 发送数据到设备
func (d *Device) Write(data []byte) (int, error) {
	if len(data) == 0 {
		return 0, nil
	}
	d.mu.Lock()
	defer d.mu.Unlock()

	var transferred uint32
	r, _, err := procWinUsb_WritePipe.Call(
		d.usbHandle,
		uintptr(d.EpOut),
		uintptr(unsafe.Pointer(&data[0])),
		uintptr(len(data)),
		uintptr(unsafe.Pointer(&transferred)),
		0,
	)
	if r == 0 {
		return 0, fmt.Errorf("WritePipe 失败: %w", err)
	}
	return int(transferred), nil
}

// Read 从设备读取数据
func (d *Device) Read(bufSize int) ([]byte, error) {
	d.mu.Lock()
	defer d.mu.Unlock()

	buf := make([]byte, bufSize)
	var transferred uint32
	r, _, err := procWinUsb_ReadPipe.Call(
		d.usbHandle,
		uintptr(d.EpIn),
		uintptr(unsafe.Pointer(&buf[0])),
		uintptr(bufSize),
		uintptr(unsafe.Pointer(&transferred)),
		0,
	)
	if r == 0 {
		return nil, fmt.Errorf("ReadPipe 失败: %w", err)
	}
	return buf[:transferred], nil
}

// Flush 清空管道缓冲
func (d *Device) Flush() {
	procWinUsb_FlushPipe.Call(d.usbHandle, uintptr(d.EpIn))
	procWinUsb_FlushPipe.Call(d.usbHandle, uintptr(d.EpOut))
}

// Close 关闭设备
func (d *Device) Close() {
	if d.usbHandle != 0 {
		procWinUsb_Free.Call(d.usbHandle)
		d.usbHandle = 0
	}
	if d.devHandle != windows.InvalidHandle {
		windows.CloseHandle(d.devHandle)
		d.devHandle = windows.InvalidHandle
	}
}

// Info 打印设备信息
func (d *Device) Info() string {
	return fmt.Sprintf("WinUSB Device | VID=%s PID=%s | EpOut=0x%02X EpIn=0x%02X | Path=%s",
		d.VID, d.PID, d.EpOut, d.EpIn, d.Path)
}

func main() {
	dev, err := OpenAuto()
	if err != nil {
		log.Fatalf("打开失败: %v", err)
	}
	defer dev.Close()

	fmt.Println(dev.Info())
	dev.Flush()
	fileData, err := os.ReadFile(`C:\Users\15629\Desktop\测试压缩包\txbz_json_UAE_20260617102703.zip`)
	// 发送
	n, err := dev.Write(fileData)
	if err != nil {
		log.Fatalf("Write: %v", err)
	}
	fmt.Printf("发送: %d 字节\n", n)

	// 接收
	data, err := dev.Read(512)
	if err != nil {
		log.Fatalf("Read: %v", err)
	}
	fmt.Printf("收到: %q\n", data)
}
