package main

import (
	"fmt"
	"github.com/PagerDuty/godspeed"
	"time"
)

func main() {
	go func() {
		t := time.NewTicker(3 * time.Second) // 3秒おきに通知
		for {
			select {
			case <-t.C:
				fmt.Printf("3 sec elapsed.")

				g, err := godspeed.NewDefault()

				if err != nil {
					panic(err)
				}

				defer g.Conn.Close()

				tags := []string{"example"}

				err = g.Send("example.stat", "g", 1, 1, tags)

				if err != nil {
					panic(err)
				}

				err = g.Count("example.count", 1, nil)

				if err != nil {
					panic(err)
				}

			}
		}
		t.Stop() // タイマを止める。
	}()
	time.Sleep(60 * 1000 * time.Millisecond)
}
