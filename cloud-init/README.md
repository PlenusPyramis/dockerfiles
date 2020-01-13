# Cloud-Init

A collection of cloud-init scripts.

All files are made available under the terms of this [MIT License](../LICENSE)

Files in this directory contain what is called cloud-init 'User data', which you
copy, and edit, in order to configure your own personal deployment, and all of
its settings, in one file. Save a copy of the file, edit it, and then when you
create your droplet, you paste your edited version into the 'User data' section
of the droplet creation screen on Digital Ocean (or theoretically any other
cloud-init enabled environment/service.) From then on, the install is fully
automatic.

These are tested with the Digital Ocean Marketplace Docker application. They do
not install Docker, it assumes that Docker is already installed/ready-to-go in
the droplet image. So when creating your droplet, don't choose regular Ubuntu,
instead choose the Docker app from the Marketplace tab, which is maintained by
Digital Ocean and has an up-to-date Docker version preinstalled. Then choose the
droplet size and other details as you normally would. When you get to one of the
checkboxes that says 'User data', check it, and paste the whole edited file
(comments and all!) into the text box that appears. When you finish and create
the droplet, it will automatically boot and setup everything exactly as you have
configured in the file, without any further setup. Save the file for later, and
it'll be nice and repeatable next time, just copy and paste. Neat, huh?

If you are a developer, or are doing lots of testing with cloud-init, it might
get tiresome using the web browser to recreate your droplet each time. Check out
the included [developer tool](droplet.sh) I wrote that automates these boring
tasks.
