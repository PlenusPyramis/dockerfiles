echo "I'm the container specific run script"
echo "Here's the contents of a few files that was pre-poulated for me by docker_configurator:"
echo " - /etc/my_app/my_config.cfg:"
cat -n /etc/my_app/my_config.cfg
echo " - /etc/my_other_app/name.conf"
cat -n /etc/my_other_app/name.conf
if [ ! -f /etc/my_other_app/name.conf ]; then
    echo "Oh, looks like the template for /etc/my_other_app/name.conf never ran!"
    echo "That's probably because you did not specify the user config."
fi
