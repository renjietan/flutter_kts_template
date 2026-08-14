package protocol

import (
	"bytes"
	"errors"
)

var Magic = []byte{0xEE, 0xDD, 0xCC, 0xBB}

const (
	FieldPacketSession = 1
	FieldPacketMessage = 2

	BodyDiscoverNty        = 3
	BodyDiscoverRsp        = 4
	BodyAuthNty            = 5
	BodyAuthRsp            = 6
	BodyTransferStartNty   = 7
	BodyTransferChunkNty   = 8
	BodyTransferProgressRsp = 9
	BodyTransferEndNty     = 10
	BodyTransferLossReq    = 11
	BodyTransferCompleteRsp = 12
	BodyParseCompleteReq   = 13
	BodyParseCompleteAck   = 14
)

type Packet struct {
	SessionID []byte
	MessageID []byte
	BodyField int
	Body      []byte
}

type Fields struct {
	Bytes   map[int][]byte
	Varints map[int]uint64
}

func ParseBodyFields(body []byte) *Fields {
	return parseFields(body)
}

func DecodePacket(data []byte) (*Packet, error) {
	if len(data) < 4 || !bytes.Equal(data[:4], Magic) {
		return nil, errors.New("bad magic")
	}
	fields := parseFields(data[4:])
	p := &Packet{}
	if v, ok := fields.Bytes[FieldPacketSession]; ok {
		p.SessionID = v
	}
	if v, ok := fields.Bytes[FieldPacketMessage]; ok {
		p.MessageID = v
	}
	for field, value := range fields.Bytes {
		if field >= BodyDiscoverNty && field <= BodyParseCompleteAck {
			p.BodyField = field
			p.Body = value
			break
		}
	}
	if len(p.SessionID) != 16 || len(p.MessageID) != 16 {
		return nil, errors.New("invalid uuid length")
	}
	return p, nil
}

func EncodePacket(sessionID, messageID []byte, bodyField int, body []byte) []byte {
	var buf bytes.Buffer
	writeBytes(&buf, FieldPacketSession, sessionID)
	writeBytes(&buf, FieldPacketMessage, messageID)
	writeBytes(&buf, bodyField, body)
	return buf.Bytes()
}

func Frame(packet []byte) []byte {
	out := make([]byte, 0, len(Magic)+len(packet))
	out = append(out, Magic...)
	out = append(out, packet...)
	return out
}

func ParseFields(data []byte) *Fields {
	return parseFields(data)
}

func writeBytes(buf *bytes.Buffer, field int, value []byte) {
	writeVarint(buf, uint64(field<<3|2))
	writeVarint(buf, uint64(len(value)))
	buf.Write(value)
}

func writeVarint(buf *bytes.Buffer, v uint64) {
	for v >= 0x80 {
		buf.WriteByte(byte(v) | 0x80)
		v >>= 7
	}
	buf.WriteByte(byte(v))
}

func parseFields(data []byte) *Fields {
	res := &Fields{
		Bytes:   map[int][]byte{},
		Varints: map[int]uint64{},
	}
	for offset := 0; offset < len(data); {
		key, n := readVarint(data[offset:])
		if n == 0 {
			break
		}
		offset += n
		field := int(key >> 3)
		wire := int(key & 0x07)
		switch wire {
		case 0:
			v, n := readVarint(data[offset:])
			offset += n
			res.Varints[field] = v
		case 2:
			length, n := readVarint(data[offset:])
			if n == 0 {
				break
			}
			offset += n
			if offset+int(length) > len(data) {
				break
			}
			res.Bytes[field] = data[offset : offset+int(length)]
			offset += int(length)
		default:
			return res
		}
	}
	return res
}

func readVarint(data []byte) (uint64, int) {
	var v uint64
	for i := 0; i < len(data); i++ {
		b := data[i]
		v |= uint64(b&0x7F) << (7 * i)
		if b < 0x80 {
			return v, i + 1
		}
	}
	return 0, 0
}

func EncodeString(field int, value string) []byte {
	var buf bytes.Buffer
	writeBytes(&buf, field, []byte(value))
	return buf.Bytes()
}

func EncodeVarint(field int, value uint64) []byte {
	var buf bytes.Buffer
	writeVarint(&buf, uint64(field<<3|0))
	writeVarint(&buf, value)
	return buf.Bytes()
}

func JoinBytes(parts ...[]byte) []byte {
	return bytes.Join(parts, nil)
}
