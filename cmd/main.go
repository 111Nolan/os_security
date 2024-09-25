package main

import (
	"context"
	"os"
	"secsys"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func main() {
	cmd := &cobra.Command{
		Use: "secsys",
		Run: func(cmd *cobra.Command, args []string) {
			s, err := secsys.New()
			if err != nil {
				logrus.Fatal(err)
			}

			if err := s.Run(context.Background()); err != nil {
				logrus.Fatal(err)
			}
		},
	}
	if cmd.Execute() != nil {
		os.Exit(1)
	}
}
