Bottleneck = require "bottleneck"
url = require "url"
http = require "http"
util = require "util"
con = () -> util.puts Array::slice.call(arguments, 0).map((a)->util.inspect a).join " "
rURL = new RegExp "/r/.*$"
rWord = new RegExp "[a-zA-Z\-'.:/]", "g"
rCaps = new RegExp "[A-Z]", ""
rand = (s, e) -> (Math.floor (Math.random()*(e-s+1)))-s
Array::random = () -> @[rand(0,@.length-1)]
limiter = new Bottleneck 5, 200

String::fsplit = (pred) ->
	buf = ""
	ret = []
	for c in @
		buf += c
		if pred buf
			# Add all elements except the last one
			ret.push buf[..-2]
			buf = if not pred c then c else ""
	ret.push buf
	ret.filter (a) -> a.length > 0

getPage = (addr, cb) ->
	data = ""
	req = http.request {
		hostname: "www.reddit.com"
		port: 80
		method: "GET"
		path: addr
		headers:{
			"user-agent": "Reddit-Node-Bot v0.1"
		}
	}, (res) ->
		res.on "data", (chunk) ->
			data += chunk.toString "utf8"
		res.on "end", () ->
			cb null, data
	req.on "error", (err) ->
		cb err
	req.end()

generateBullshit = (addr, _) ->
	data = JSON.parse limiter.submit getPage, addr+".json", _
	if data.error? then throw new Error JSON.stringify data

	top = data[1].data.children
	title = data[0].data.children[0].data.title
	replies = [title]
	addReply = (post) ->
		replies.push post.data.body
		post.data.replies?.data?.children?.forEach (c) -> addReply c
	top.forEach (c) -> addReply c

	pairs = {}
	starts = []
	replies.filter (r) ->
			r?
		.map (r) ->
			r+(if r[-1..] != "." then "." else "")
		.forEach (r) ->
			words = r.fsplit (a) ->
				not rWord.test a
			.forEach (w, i, words) ->
				if i != words.length-1
					if rCaps.test w.trim()[0]
						starts.push w
					if pairs[w]?
						pairs[w].push words[i+1]
					else
						pairs[w] = [words[i+1]]

	strs = []
	for i in [1..10]
		str = starts.random()
		lastWord = str
		while lastWord[-1..] != "."
			nextWord = pairs[lastWord].random()
			str += " "+nextWord
			lastWord = nextWord
		strs.push str
	strs

handler = (req, res, _) ->
	ret = try
		parsed = url.parse req.url, true
		addr = parsed.pathname.match(rURL)[0]
		console.log (new Date).toISOString()+" "+addr
		JSON.stringify generateBullshit addr, _
	catch err
		con err
		err.message
	ret = if parsed.query.callback?
		parsed.query.callback+"("+ret+");"
	else
		ret
	res.writeHead 200, {"Content-type":"text/json"}
	res.end ret

http.createServer((req, res) ->
	handler req, res, ->
).listen "./socket/reddit-markov.sock"
