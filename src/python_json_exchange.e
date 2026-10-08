note
	description: "[
		One JSON request/response exchange over HTTP, shared by the bridges.

		The request body leaves byte-for-byte, labeled application/json, through
		SIMPLE_WINHTTP. SIMPLE_HTTP was used before 1.0.2 and could not carry JSON:
		its transport (ISE curl_http_client, command-line spec) splices the body
		unescaped into ` --data "<body>"` on a curl command line, so every double
		quote in the JSON was stripped (and a space split the argument) before the
		request left the machine. The Python server then saw
		{message_id:test_msg_001,...} and answered INVALID_JSON.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-10-08"
	license: "MIT"

class
	PYTHON_JSON_EXCHANGE

create
	make

feature {NONE} -- Initialization

	make
			-- An exchange that has not been sent yet.
		do
			create client.make
			create body.make_empty
			create error.make_empty
		ensure
			not_sent: status = 0
			no_body: body.is_empty
			no_error: error.is_empty
		end

feature -- Access

	status: INTEGER
			-- HTTP status of the last `post'; 0 when nothing was exchanged.

	body: STRING_32
			-- Response body of the last `post', decoded from UTF-8.

	error: STRING_32
			-- Transport failure reason of the last `post'; empty when an answer came back.

feature -- Status report

	is_exchanged: BOOLEAN
			-- Did the last `post' reach a server and get an answer back?
		do
			Result := status > 0
		ensure
			definition: Result = (status > 0)
		end

	is_usable_url (a_url: READABLE_STRING_8): BOOLEAN
			-- Can `post' send to `a_url' (an ASCII http(s) URL)?
		do
			Result := client.is_web_url (a_url) and then client.is_ascii_url (a_url)
		end

feature -- Basic operations

	post (a_url, a_json: READABLE_STRING_8; a_timeout_seconds: INTEGER)
			-- POST the UTF-8 JSON text `a_json' to `a_url' as application/json,
			-- waiting up to `a_timeout_seconds' for the answer, and record it.
			-- A network failure is recorded in `error', never raised.
		require
			usable_url: is_usable_url (a_url)
			json_not_empty: not a_json.is_empty
			positive_timeout: a_timeout_seconds > 0
		local
			l_headers: HASH_TABLE [STRING_8, STRING_8]
			l_response: SIMPLE_WINHTTP_RESPONSE
		do
			create l_headers.make (1)
			l_headers.put ("application/json", "Content-Type")
			l_response := client.send ("POST", a_url, l_headers, a_json, a_timeout_seconds)
			status := l_response.status
			body := {UTF_CONVERTER}.utf_8_string_8_to_string_32 (l_response.body)
			error := l_response.error.twin
		ensure
			status_recorded: status >= 0
			failure_explained: not is_exchanged implies not error.is_empty
		end

feature {NONE} -- Implementation

	client: SIMPLE_WINHTTP
			-- Transport.

invariant
	status_non_negative: status >= 0

end
