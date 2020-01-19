package cmd

import (
	"context"
	"fmt"
	"github.com/AlecAivazis/survey"
	"github.com/plenuspyramis/dockerfiles/digitalocean-k3sup"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// deployCmd represents the deploy command
var deployCmd = &cobra.Command{
	Use:   "deploy",
	Short: "Deploy k3s to digitalocean",
	Long:  ``,
	RunE: func(cmd *cobra.Command, args []string) error {
		if viper.GetBool("interactive") {
			err := interactiveArgs()
			if err != nil {
				return err
			}
		}
		deploy(viper.GetInt("cluster_size"), viper.GetString("machine_size"), viper.GetStringSlice("ssh_fingerprints"))
		//deploy(viper.Get)
		return nil // return errors.New("errorzzzz")
	},
}

func init() {
	rootCmd.AddCommand(deployCmd)
	deployCmd.Flags().BoolP("interactive", "", viper.GetBool("interactive"), "Interactive configuration")
	viper.BindPFlag("interactive", deployCmd.Flags().Lookup("interactive"))
}

func interactiveArgs() error {
	fmt.Println("Getting args interactively")

	apiKey := ""
	survey.AskOne(&survey.Input{Message: "Enter your Digital Ocean API Key:"}, &apiKey, survey.WithValidator(survey.Required))
	viper.Set("api_key", apiKey)

	ctx := context.TODO()
	client := getClient(ctx, apiKey)

	machineSizes, _, err := client.Sizes.List(ctx, &godo.ListOptions{Page: 0, PerPage: 200})
	if err != nil {
		return err
	}
	fmt.Println(machineSizes)

	viper.Set("cluster_size", 1)
	viper.Set("machine_size", "s-1vcpu-1gb")
	viper.Set("ssh_fingerprints", []string{"76:ef:9f:d2:36:c9:c1:36:79:a5:8c:15:fb:bc:d8:64", "e6:ac:de:dc:41:63:d6:56:b7:d2:ee:c3:56:b8:4e:47"})
	return nil
}

func deploy(clusterSize int, machineSize string, sshFingerprints []string) error {
	fmt.Println("calling deploy", clusterSize, machineSize, sshFingerprints)
	return nil
}
