# fbmsgr

_Reverse engineering Facebook Messenger._

[![GoDoc: reference][godoc-img]][godoc] [![Tags][tags-img]][tags]

This is a fork of [`unixpickle/fbmsgr`](https://github.com/unixpickle/fbmsgr)
which contains a modified `Session` struct with an exposed `http.Client`, so
that its cookies may be read by other packages.

### Original README:

> This is a wrapper around [Facebook Messenger's](https://messenger.com) internal
> AJAX protocol. This wrapper could be used for any number of cool things, such
> as:
>
> - Tracking your friends' Messenger activity.
> - Analyzing your conversations (e.g. keywords analysis)
> - Automating "Away" messages
> - Creating chat bots
>
> ## Current status
>
> Currently, the API is fairly reliable and can perform a bunch of basic
> functionalities. Here is a list of supported features (it may lag slightly
> behind the master branch):
>
> - Send textual messages to people or groups
> - Send attachments to people or groups
> - Receive messages with or without attachments
> - Send read receipts
> - Receive events for incoming messages
> - Receive events for friend "Last Active" updates
> - Set chat text colors (to arbitrary RGB colors)
> - List a user's threads.
> - List messages in a thread.
> - Send and receive typing events
> - Delete messages
>
> ## TODOs
>
> - Support emojis in threads (i.e. the like button)
> - In FullActionLog, remove _all_ duplicates, incase two messages have the same
>   timestamp.
> - Emoji/sticker transmission
> - Modifying chat preferences (emoji, nicknames, etc.)
> - View pending message requests
> - Create new group chats
>
> ## License
>
> This is under a BSD 2-clause license. See [LICENSE](./LICENSE).

[godoc]: https://godoc.org/github.com/stevenxie/fbmsgr
[godoc-img]: https://godoc.org/github.com/stevenxie/fbmsgr?status.svg
[tags]: https://github.com/stevenxie/fbmsgr/tags
[tags-img]: https://img.shields.io/github/tag/stevenxie/fbmsgr.svg
