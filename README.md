reddit-markov-chains
====================

Generate ridiculous sentences from reddit comments.

It works by parsing all comments in a reddit post and building a probabilities table for each word. Ex: "I" has 29% chance of being followed by "am", 17% by "have, etc. Then it picks a random that was used to begin a comment and adds one word at a time from the probabilities table until it reaches a word that was used to end a sentence. Repeat 9 times to get 10 sentences.

To run it:

```
npm install bottleneck
node index.js &> out.txt &
```

That will read incoming requests from ./socket/reddit-markov.sock (UNIX socket).

To read from a TCP port, edit the last line. Example: "listen(80)" to read from port 80.
