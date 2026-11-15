# ha-automations-config-template

Template for your [ha-automations](https://github.com/joshwlivingston/ha-automations)
config repo. Edit `apps.yaml`, push, and the included workflow deploys it to
Home Assistant OS.

**Setup takes about 15 minutes.**

---

## What you need

- Home Assistant OS with the **AppDaemon** add-on installed
- The **Advanced SSH & Web Terminal** add-on, set up for key login
  (the basic SSH add-on won't work, because deploys need its Supervisor access)
- A computer on your home network that stays on to run deploys, with `git`,
  `ssh` and `rsync` (a Raspberry Pi, NAS or old laptop is plenty)
- A GitHub account

---

## Quick start

### 1. Make your copy

Click **Use this template** at the top of this page, then **Create a new
repository**. Choose **Private**, since your settings contain your home's private data.

### 2. Choose your apps

Open `apps.yaml`. Each entry is one app with its settings. Replace the example
entity IDs, such as `light.bedroom_lamp`, with your own. Delete the entries you
don't need, or copy one under a new name to run an app again. The
[docs](https://joshwlivingston.github.io/ha-automations/) list every app and
its settings.

> **Finding an entity ID:** in Home Assistant, go to **Settings > Devices &
> services > Entities**, search for the device, and copy its **Entity ID**.

### 3. Give GitHub a computer at home

GitHub can't reach your home network, so deploys run on a computer inside it.

1. In your new repo, go to **Settings > Actions > Runners > New self-hosted runner**.
2. Pick your computer's OS and run the commands GitHub shows, on that computer.
3. Still on that computer, check it can log in to Home Assistant without a password:

   ```sh
   ssh root@homeassistant.local "echo it works"
   ```

   If it asks for a password, run `ssh-copy-id root@homeassistant.local`, or add
   the computer's public key to the SSH add-on's `authorized_keys` setting.

### 4. Tell the workflow where Home Assistant is

1. Go to **Settings > Environments > New environment** and name it `haos`.
2. Under **Environment variables**, add:

   | Name | Value |
   |---|---|
   | `HA_SSH` | `root@homeassistant.local` (or `root@<your HA IP>`) |
   | `PACKAGE_REPO` | `joshwlivingston/ha-automations` |

   That's all most people need. [All settings](#all-settings) lists the rest.

### 5. Deploy

Commit your `apps.yaml` change to `main`, then open the **Actions** tab to
watch it run. A green check means your apps are deployed.

### 6. Try it now

Every app has a test event, so you don't need to wait for it to run on its own
(for Sunrise Fade, until dawn).

1. In Home Assistant, go to **Developer tools > Events**.
2. Under **Fire an event**, enter your app's name followed by `_start`, for
   example `bedroom_sunrise_start`.
3. Click **Fire event**.

If the app has something to do right now, it does it. Otherwise the AppDaemon
log says so, for example `bedroom_sunrise: outside fade, nothing to do`. That
means it's working and waiting for the right time.

---

## Day to day

| To... | Do this |
|---|---|
| Change a setting | Edit `apps.yaml` and push to `main`. It deploys in a minute or two. |
| Get a new ha-automations release | Nothing. It installs within 15 minutes during the day, or an hour overnight. |
| Redeploy by hand | **Actions > Deploy > Run workflow**. Tick **force** to redeploy even when nothing changed. |
| Install a specific version | **Actions > Deploy > Run workflow** and enter a tag like `v0.4.0`. |
| Try a dev build | **Actions > Deploy > Run workflow** with **dev** ticked. It installs the newest tag, dev tags included, or the dev tag you enter (like `v0.4.0.9001`). Later deploys keep it until a newer release comes out. To go back sooner, run it again with **dev** unticked. |
| Roll back | Run it with an older tag, then disable the workflow so the next check doesn't reinstall the latest. Turn it back on once a fix is out. |
| Pause deploys | **Actions > Deploy > ... > Disable workflow**. |

---

## Troubleshooting

**The workflow is stuck on "Waiting for a runner".**
Your home computer's runner is offline. Check **Settings > Actions > Runners**
and start it again.

**The deploy fails at SSH.**
On the runner's computer, run `ssh root@homeassistant.local`. It must log in
without a password. Check `HA_SSH`, and set `HA_SSH_PORT` if you don't use port 22.

**The deploy fails with `no SUPERVISOR_TOKEN in SSH session`.**
You're connecting through the basic SSH add-on. Switch to **Advanced SSH & Web
Terminal**.

**The deploy fails at "Resolve version".**
- `no matching tags` means `PACKAGE_REPO` is missing or wrong. Set it to
  `joshwlivingston/ha-automations`.
- `could not read a0d7b954_appdaemon options` means SSH failed (see above) or your
  AppDaemon add-on has a different slug. Set `ADDON_SLUG` to match.

**The deploy refuses a dev tag.**
Dev tags (like `v0.4.0.9001`) only install when you tick **dev** on a manual run.

**An app doesn't do anything.**
Open the **AppDaemon** add-on and select **Log**.
- `bedroom_sunrise loaded: ...` means the app is running. Fire the test event
  from [step 6](#6-try-it-now).
- `Extra inputs are not permitted` means a setting name is misspelled. Typos are
  rejected on purpose, so they show up here instead of being quietly ignored.
- `Field required` means a required setting is missing.

**Deploys run at odd hours.**
The schedule is set for US Mountain time. Edit the two `cron` lines at the top of
`.github/workflows/deploy.yml` for your time zone. They are in UTC.

---

## All settings

Set these on the `haos` environment, or on the repo under
**Settings > Secrets and variables > Actions > Variables**.

| Variable | Needed? | Example | What it does |
|---|---|---|---|
| `HA_SSH` | **Yes** | `root@192.168.1.10` | How to SSH to Home Assistant |
| `PACKAGE_REPO` | **Yes**, unless you forked ha-automations | `joshwlivingston/ha-automations` | Where to install the apps from. Defaults to `<your account>/ha-automations`. |
| `HA_SSH_PORT` | No | `22` | SSH port. Defaults to 22. |
| `ADDON_SLUG` | No | `a0d7b954_appdaemon` | The AppDaemon add-on's slug. Defaults to `a0d7b954_appdaemon`. |
| `RUNNER_LABELS` | No | `["self-hosted", "homelab"]` | Which runner to use, as a JSON list. Defaults to `["self-hosted"]`. |

---

## What's in this repo

| File | What it is |
|---|---|
| `apps.yaml` | Your apps and their settings. The only file most people edit. |
| `.github/workflows/deploy.yml` | Installs everything on Home Assistant. |
| `scripts/resolve-version.sh` | Picks which ha-automations tag to install. |
