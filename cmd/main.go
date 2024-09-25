package main

import (
	"context"
	"secsys"

	"github.com/sirupsen/logrus"
	//"fmt"
)

func main() {
	//fmt.Println("test")
	
	s, err := secsys.New()
	if err != nil {
		logrus.Fatal(err)
	}

	if err := s.Run(context.Background()); err != nil {
		logrus.Fatal(err)
	}

}
