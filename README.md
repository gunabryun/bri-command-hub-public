# Bri Command Hub

A local-first Android workspace for focused content work, file hygiene, and optional offline drafting.

![Bri Command Hub banner](assets/bri-command-hub-banner.svg)

## What it does

- Creates private content and WhatsApp-caption drafts, never sends them
- Generates a first-build milestone card locally for review
- Lists generated workspace files
- Moves one named regular file to quarantine and restores it later
- Offers an opt-in, read-only root-status diagnostic
- Includes **Mini-Toqi**, an optional local model for offline draft help

## Mini-Toqi, optional local drafting

Mini-Toqi is not a copy of the hosted Toqi service. It is a small, local-only drafting helper that runs inside Termux after a one-time model download. It can help make short draft text and ideas when offline, but it is intentionally limited:

- It does not read WhatsApp chats, email, contacts, phone files or accounts
- It does not send messages, post a Status, browse, pay, book, change phone settings or run root
- Its text is always a draft for Bri to review, never a command to execute
- Do not enter passwords, codes, banking details, recovery phrases, private chats or legal records

The first model is SmolLM2 360M Instruct in a small ARM-friendly 4-bit format, about 230 MB. It is deliberately modest, so it may be slower and less accurate than Toqi. The Hub still works normally without it.

## Safety by design

Bri Command Hub uses fixed, visible actions instead of accepting arbitrary shell commands. Ordinary work runs as the normal Termux user. It does not read WhatsApp chats, send messages, publish Status updates, hide root, weaken Android security, install unrelated apps, or change phone settings.

A WhatsApp Status handoff always ends in WhatsApp, where you review the media, choose the audience and tap the final Send control yourself.

## Install or update in Termux

```sh
git clone https://github.com/gunabryun/bri-command-hub-public.git
cd bri-command-hub-public
bash install.sh
~/.local/bin/bri-hub init
```

If the project is already on your phone, update it first:

```sh
cd ~/bri-command-hub-public && git pull --ff-only && bash install.sh
```

## Try the Hub

```sh
~/.local/bin/bri-hub status
~/.local/bin/bri-hub write localsend-guide
~/.local/bin/bri-hub post milestone
~/.local/bin/bri-hub card
~/.local/bin/bri-hub files
```

## Try Mini-Toqi

Mini-Toqi needs roughly 850 MB free storage for the runner, model and safe working space. It uses mobile data or Wi-Fi only for the one-time download.

```sh
~/.local/bin/mini-toqi install
```

Then, after the download completes:

```sh
~/.local/bin/mini-toqi check
```

```sh
~/.local/bin/mini-toqi ask "Draft a short encouragement for my customers"
```

To remove only the downloaded model later, while keeping the Hub and all drafts:

```sh
~/.local/bin/mini-toqi remove-model CONFIRM
```

## Roadmap

See [ROADMAP.md](ROADMAP.md) for the next practical steps and the project boundaries.

## Project status

Early public build. Built by Brian Guna as part of NexVanta’s practical Android and Linux work, with a focus on local-first tools and clear human approval.

## Notes

Review the scripts before running them and use the Hub only on files in its own workspace.
