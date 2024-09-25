package secsys

import (
	"bytes"
	"context"
	"encoding/binary"
	"errors"

	"github.com/cilium/ebpf/link"
	"github.com/cilium/ebpf/perf"
	"github.com/cilium/ebpf/rlimit"
	"github.com/sirupsen/logrus"
	"golang.org/x/sys/unix"
)

type Server interface {
	Run(context.Context) error
	Watch()
}

type server struct {
	objs *bpfObjects
}

func New() (Server, error) {
	s := &server{}
	return s, nil
}

func (s *server) Run(ctx context.Context) error {
	// load ebpf
	if err := rlimit.RemoveMemlock(); err != nil {
		return err
	}

	s.objs = &bpfObjects{}
	if err := loadBpfObjects(s.objs, nil); err != nil {
		return err
	}
	defer s.objs.Close()

	kp, err := link.Kprobe("do_sys_openat2", s.objs.DoSysOpenat2, nil)
	if err != nil {
		return err
	}
	defer kp.Close()

	go s.Watch()

	<-ctx.Done()
	return nil
}

func (s *server) Watch() {
	reader, err := perf.NewReader(s.objs.Events, 8192)
	if err != nil {
		logrus.Println(err)
		return
	}
	defer reader.Close()

	logrus.Println("Waiting for events...")

	for {
		record, err := reader.Read()
		if err != nil {
			if errors.Is(err, perf.ErrClosed) {
				logrus.Println("Received signal, exiting...")
				return
			}
			logrus.Printf("reading from reader: %s", err)
			continue
		}
		if record.LostSamples > 0 {
			logrus.Printf("lost %d events", record.LostSamples)
			continue
		}

		var event Event
		if err := binary.Read(bytes.NewBuffer(record.RawSample), binary.LittleEndian, &event); err != nil {
			logrus.Printf("parse event: %s", err)
			continue
		}
		logrus.Printf("pid %d, file: %s", event.Pid, unix.ByteSliceToString(event.FileName[:]))

	}
}
