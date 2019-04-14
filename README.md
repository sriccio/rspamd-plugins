# Some SwissCenter made or modded plugins for rspamd

Here you will find some custom modules for rspamd

## Cyren

The cyren lua plugin allow you to add Cyren checks through a Cyren scanning gateway

### Installation

- Copy `plugins/lua/cyren.lua` module to your rspamd `$PLUGINSDIR` directory
- Copy `local.d/cyren*` files to your rspamd `local.d` directory
- Copy or merge `local.d/groups.conf` content with your existing `local.d/groups.conf`
- Edit `local.d/cyren.conf` to set your Cyren gateway url
- Edit `local.d/cyren_group.conf` if you want to change scoring
- Copy `rspamd.conf.local` to your rspamd config folder (usually `/etc/rspamd`) or merge the content if you already use one.
- Restart rspamd

