package session

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"time"

	"cpdc/internal/config"
	"cpdc/internal/net"
	"cpdc/internal/protocol"
)

type Session struct {
	cfg       *config.Config
	transport *net.Transport
	nonce     []byte
	act       *active
}

type active struct {
	sessionID []byte
	chunks    map[int][]byte
	start     *transferStart
}

type transferStart struct {
	name   string
	size   int
	hash   []byte
	chunks int
}

func New(cfg *config.Config, transport *net.Transport) *Session {
	nonce := make([]byte, 16)
	// crypto/rand is preferable here; for the scaffold use the config package helper
	copy(nonce, []byte(fmt.Sprintf("%016d", time.Now().UnixNano())))
	return &Session{cfg: cfg, transport: transport, nonce: nonce}
}

func (s *Session) Run() error {
	for {
		data, _, err := s.transport.Read()
		if err != nil {
			return err
		}
		pkt, err := protocol.DecodePacket(data)
		if err != nil {
			continue
		}
		switch pkt.BodyField {
		case protocol.BodyDiscoverNty:
			s.handleDiscover(pkt)
		case protocol.BodyAuthNty:
			s.handleAuth(pkt)
		case protocol.BodyTransferStartNty:
			s.handleStart(pkt)
		case protocol.BodyTransferChunkNty:
			s.handleChunk(pkt)
		case protocol.BodyTransferEndNty:
			s.handleEnd(pkt)
		case protocol.BodyParseCompleteAck:
			s.handleAck(pkt)
		}
	}
}

func (s *Session) handleDiscover(pkt *protocol.Packet) {
	ip, mask, err := net.FirstInterfaceIP()
	if err != nil {
		return
	}
	var body bytes.Buffer
	body.Write(protocol.EncodeString(1, s.cfg.ESN))
	body.Write(protocol.EncodeString(2, string(s.nonce)))
	for _, t := range s.cfg.DeviceTypes {
		body.Write(protocol.EncodeVarint(3, deviceTypeValue(t)))
	}
	body.Write(protocol.EncodeString(4, ip))
	body.Write(protocol.EncodeString(5, mask))
	packet := protocol.EncodePacket(pkt.SessionID, pkt.MessageID, protocol.BodyDiscoverRsp, body.Bytes())
	_ = s.transport.Broadcast(protocol.Frame(packet))
	log.Printf("cpdc: replied DISCOVER_RSP esn=%s ip=%s", s.cfg.ESN, ip)
}

func (s *Session) handleAuth(pkt *protocol.Packet) {
	var body bytes.Buffer
	body.Write(protocol.EncodeVarint(1, 1)) // result success
	body.Write(protocol.EncodeString(2, s.cfg.ESN))
	for _, t := range s.cfg.DeviceTypes {
		body.Write(protocol.EncodeVarint(3, deviceTypeValue(t)))
	}
	packet := protocol.EncodePacket(pkt.SessionID, pkt.MessageID, protocol.BodyAuthRsp, body.Bytes())
	_ = s.transport.Broadcast(protocol.Frame(packet))
	log.Printf("cpdc: replied AUTH_RSP success")
}

func (s *Session) handleStart(pkt *protocol.Packet) {
	fields := protocol.ParseBodyFields(pkt.Body)
	name := string(fields.Bytes[1])
	size := int(fields.Varints[2])
	hash := fields.Bytes[3]
	chunkSize := int(fields.Varints[6])
	totalChunks := int(fields.Varints[7])
	if chunkSize == 0 {
		chunkSize = 1200
	}
	if totalChunks == 0 {
		totalChunks = (size + chunkSize - 1) / chunkSize
	}
	s.act = &active{
		sessionID: append([]byte(nil), pkt.SessionID...),
		chunks:    map[int][]byte{},
		start: &transferStart{
			name:   name,
			size:   size,
			hash:   append([]byte(nil), hash...),
			chunks: totalChunks,
		},
	}
	log.Printf("cpdc: TRANSFER_START_NTY name=%s size=%d chunks=%d", name, size, totalChunks)
}

func (s *Session) handleChunk(pkt *protocol.Packet) {
	if s.act == nil || !bytes.Equal(pkt.SessionID, s.act.sessionID) {
		return
	}
	fields := protocol.ParseBodyFields(pkt.Body)
	index := int(fields.Varints[1])
	payload := fields.Bytes[2]
	if len(payload) == 0 {
		return
	}
	s.act.chunks[index] = append([]byte(nil), payload...)
	if len(s.act.chunks)%100 == 0 {
		log.Printf("cpdc: received chunk %d/%d", len(s.act.chunks), s.act.start.chunks)
	}
}

func (s *Session) handleEnd(pkt *protocol.Packet) {
	if s.act == nil || !bytes.Equal(pkt.SessionID, s.act.sessionID) {
		return
	}
	missing := s.missingChunks()
	if len(missing) > 0 {
		s.sendLossRequest(pkt.SessionID, pkt.MessageID, missing)
		return
	}

	var body bytes.Buffer
	body.Write(protocol.EncodeString(1, s.cfg.ESN))
	body.Write(protocol.EncodeVarint(2, 1)) // result success
	packet := protocol.EncodePacket(pkt.SessionID, pkt.MessageID, protocol.BodyTransferCompleteRsp, body.Bytes())
	_ = s.transport.Broadcast(protocol.Frame(packet))
	log.Printf("cpdc: replied TRANSFER_COMPLETE_RSP success")
	s.sendParseComplete(pkt.SessionID)
}

func (s *Session) missingChunks() []int {
	if s.act == nil || s.act.start == nil {
		return nil
	}
	var missing []int
	for i := 0; i < s.act.start.chunks; i++ {
		if _, ok := s.act.chunks[i]; !ok {
			missing = append(missing, i)
		}
	}
	return missing
}

func (s *Session) sendLossRequest(sessionID, messageID []byte, missing []int) {
	// 把连续缺失序号合并为闭区间，并原样携带 client 身份。
	var body bytes.Buffer
	body.Write(protocol.EncodeString(1, s.cfg.ESN))
	for _, t := range s.cfg.DeviceTypes {
		body.Write(protocol.EncodeVarint(2, deviceTypeValue(t)))
	}
	start, end := missing[0], missing[0]
	for i := 1; i <= len(missing); i++ {
		if i == len(missing) || missing[i] != end+1 {
			var rangeBody bytes.Buffer
			rangeBody.Write(protocol.EncodeVarint(1, uint64(start)))
			rangeBody.Write(protocol.EncodeVarint(2, uint64(end)))
			body.Write(protocol.EncodeString(3, string(rangeBody.Bytes())))
			if i < len(missing) {
				start, end = missing[i], missing[i]
			}
		} else {
			end = missing[i]
		}
	}
	packet := protocol.EncodePacket(sessionID, messageID, protocol.BodyTransferLossReq, body.Bytes())
	_ = s.transport.Broadcast(protocol.Frame(packet))
	log.Printf("cpdc: requested %d missing chunks", len(missing))
}

func (s *Session) sendParseComplete(sessionID []byte) {
	messageID := make([]byte, 16)
	copy(messageID, []byte(fmt.Sprintf("%016d", time.Now().UnixNano())))
	var body bytes.Buffer
	body.Write(protocol.EncodeString(1, s.cfg.ESN))
	body.Write(protocol.EncodeVarint(2, 1)) // result success
	for _, t := range s.cfg.DeviceTypes {
		body.Write(protocol.EncodeVarint(3, deviceTypeValue(t)))
	}
	packet := protocol.EncodePacket(sessionID, messageID, protocol.BodyParseCompleteReq, body.Bytes())
	_ = s.transport.Broadcast(protocol.Frame(packet))
	log.Printf("cpdc: sent PARSE_COMPLETE_REQ success")
}

func (s *Session) handleAck(pkt *protocol.Packet) {
	log.Printf("cpdc: received PARSE_COMPLETE_ACK")
}

func deviceTypeValue(t string) uint64 {
	switch t {
	case "Server":
		return 2
	case "IEC":
		return 3
	case "MultiBandRadio":
		return 4
	case "MultibandHandheld":
		return 5
	case "HF":
		return 6
	case "SmallHandheld":
		return 7
	case "CCU":
		return 1
	case "CCUAudio":
		return 8
	default:
		return 0
	}
}

func hashBytes(b []byte) string {
	h := sha256.Sum256(b)
	return hex.EncodeToString(h[:])
}
