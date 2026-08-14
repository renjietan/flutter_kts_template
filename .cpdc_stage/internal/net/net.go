package net

import (
	"fmt"
	"net"
)

const (
	ListenPort = 39001
	TargetPort = 39002
)

type Transport struct {
	conn   *net.UDPConn
	ifaces []net.Interface
}

func NewTransport(ifaceName string) (*Transport, error) {
	conn, err := net.ListenUDP("udp4", &net.UDPAddr{IP: net.IPv4zero, Port: ListenPort})
	if err != nil {
		return nil, err
	}
	t := &Transport{conn: conn}
	if ifaceName != "" {
		iface, err := net.InterfaceByName(ifaceName)
		if err != nil {
			conn.Close()
			return nil, fmt.Errorf("interface %s: %w", ifaceName, err)
		}
		t.ifaces = []net.Interface{*iface}
	} else {
		ifaces, err := net.Interfaces()
		if err != nil {
			conn.Close()
			return nil, err
		}
		for _, iface := range ifaces {
			if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 || iface.Flags&net.FlagBroadcast == 0 {
				continue
			}
			addrs, _ := iface.Addrs()
			if len(addrs) == 0 {
				continue
			}
			t.ifaces = append(t.ifaces, iface)
		}
		if len(t.ifaces) == 0 {
			conn.Close()
			return nil, fmt.Errorf("no qualified broadcast interface")
		}
	}
	return t, nil
}

func (t *Transport) ListenAddr() string {
	return t.conn.LocalAddr().String()
}

func (t *Transport) Close() error {
	return t.conn.Close()
}

func (t *Transport) Read() ([]byte, net.Addr, error) {
	buf := make([]byte, 1500)
	n, addr, err := t.conn.ReadFromUDP(buf)
	if err != nil {
		return nil, nil, err
	}
	return buf[:n], addr, nil
}

func (t *Transport) Broadcast(packet []byte) error {
	var last error
	for _, iface := range t.ifaces {
		addrs, _ := iface.Addrs()
		for _, addr := range addrs {
			ipn, ok := addr.(*net.IPNet)
			if !ok || ipn.IP.To4() == nil {
				continue
			}
			_ = t.sendTo(packet, net.IPv4bcast, TargetPort)
			break
		}
	}
	if err := t.sendTo(packet, net.IPv4(127, 0, 0, 1), TargetPort); err != nil {
		last = err
	}
	return last
}

func (t *Transport) sendTo(packet []byte, ip net.IP, port int) error {
	_, err := t.conn.WriteToUDP(packet, &net.UDPAddr{IP: ip, Port: port})
	return err
}

func FirstInterfaceIP() (string, string, error) {
	ifaces, err := net.Interfaces()
	if err != nil {
		return "", "", err
	}
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}
		addrs, _ := iface.Addrs()
		for _, addr := range addrs {
			ipn, ok := addr.(*net.IPNet)
			if !ok || ipn.IP.To4() == nil || ipn.IP.IsLoopback() {
				continue
			}
			mask := ipn.Mask
			if len(mask) != net.IPv4len {
				continue
			}
			return ipn.IP.String(), net.IP(mask).String(), nil
		}
	}
	return "", "", fmt.Errorf("no interface ip")
}

