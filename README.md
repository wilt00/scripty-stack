# scripty-stack

This is a work-in-progress docker-compose setup for running [Scripty](https://github.com/scripty-bot/scripty), a speech-to-text transcription bot for Discord.

## Setup

- Generate `secrets/svix_jwt_secret.txt` and `secrets/svix_main_secret.txt` - longish (30-50 chars) random base64 strings
- Run `~register_cmds` to set up slash commands
