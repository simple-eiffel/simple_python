note
	description: "[
		Base class for all messages in the Eiffel-Python bridge protocol.

		Messages are protocol-agnostic (work with HTTP, IPC, gRPC).
		Subclasses define specific message types (validation requests, responses, errors).

		Attributes are stored as generic key-value pairs (HASH_TABLE) to support
		various validation scenarios without strict schema enforcement.

		MML Model Query: attributes_model represents the mathematical state of attributes.
	]"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

deferred class
	PYTHON_MESSAGE

feature {NONE} -- Initialization

	make (a_message_id: STRING_32)
			-- Create message with unique identifier.
		require
			id_not_empty: a_message_id /= Void and then a_message_id.count > 0
		do
			message_id := a_message_id
			create attributes.make (10)
			timestamp := create {DATE_TIME}.make_now
			is_frozen := False
		ensure
			id_set: message_id.same_string (a_message_id)
			attributes_empty: attributes.count = 0
			timestamp_set: timestamp /= Void
			not_frozen_initially: not is_frozen
		end

feature -- Access

	message_id: STRING_32
			-- Unique identifier for this message.

	timestamp: DATE_TIME
			-- When message was created.

	message_type: STRING_32
			-- Type of message: VALIDATION_REQUEST, VALIDATION_RESPONSE, or ERROR.
		deferred
		end

	is_frozen: BOOLEAN
			-- Is message immutable? (true after freeze called, false initially)
			-- Prevents concurrent modification when serializing (SCOOP-safe).

feature -- Immutability

	freeze
			-- Prevent further attribute modifications (for SCOOP safety).
			-- Must be called before sending via serialize operations.
		require
			not_already_frozen: not is_frozen
		do
			is_frozen := True
		ensure
			is_frozen_now: is_frozen
		end

feature -- Attributes

	attributes: HASH_TABLE [SIMPLE_JSON_VALUE, STRING_32]
			-- Key-value attributes for flexible message representation.

feature -- Model Queries

	attributes_model: MML_MAP [STRING_32, SIMPLE_JSON_VALUE]
			-- Mathematical model of stored attributes (for MML postconditions).
		local
			l_result: MML_MAP [STRING_32, SIMPLE_JSON_VALUE]
		do
			create l_result.default_create
			across attributes as cursor loop
				l_result := l_result.updated (@cursor.key, @cursor.item)
			end
			Result := l_result
		ensure
			model_count_matches: Result.count = attributes.count
		end

feature -- Attribute Operations

	set_attribute (a_key: STRING_32; a_value: SIMPLE_JSON_VALUE)
			-- Store attribute with given key and value.
		require
			key_not_empty: a_key /= Void and then a_key.count > 0
			value_not_void: a_value /= Void
			not_frozen: not is_frozen
		do
			attributes.force (a_value, a_key)
		ensure
			attribute_set: attributes.has (a_key) and then attributes [a_key] = a_value
			-- MML Frame Condition: model updated with new key-value pair
			key_added: attributes_model.count = old attributes.count or attributes_model.count = old attributes.count + 1
		end

	get_attribute (a_key: STRING_32): detachable SIMPLE_JSON_VALUE
			-- Retrieve attribute by key, or Void if not found.
		require
			key_not_empty: a_key /= Void and then a_key.count > 0
		do
			if attributes.has (a_key) then
				Result := attributes [a_key]
			end
		end

	has_attribute (a_key: STRING_32): BOOLEAN
			-- Does message have attribute with given key?
		require
			key_not_empty: a_key /= Void and then a_key.count > 0
		do
			Result := attributes.has (a_key)
		ensure
			result_matches_contains: Result = attributes.has (a_key)
		end

	attribute_count: INTEGER
			-- Number of attributes in message.
		do
			Result := attributes.count
		ensure
			result_equals_table_count: Result = attributes.count
		end

feature -- Serialization

	to_json: SIMPLE_JSON_OBJECT
			-- Serialize message to JSON object.
			-- Includes message_id, timestamp, type, and all attributes.
		require
			is_frozen: is_frozen  -- Message must be immutable before serializing
		local
			l_attrs_obj: SIMPLE_JSON_OBJECT
			l_attrs_iter: HASH_TABLE_ITERATION_CURSOR [SIMPLE_JSON_VALUE, STRING_32]
		do
			create Result.make

			-- Add message_id field
			Result := Result.put_string (message_id, "message_id")

			-- Add type field
			Result := Result.put_string (message_type, "type")

			-- Add timestamp field (ISO-8601 format: YYYY-MM-DDTHH:MM:SS)
			Result := Result.put_string (
				timestamp.date.out + "T" + timestamp.time.out,
				"timestamp"
			)

			-- Add attributes object
			create l_attrs_obj.make
			l_attrs_iter := attributes.new_cursor
			from l_attrs_iter.start
			until l_attrs_iter.after
			loop
				if attached l_attrs_iter.item as l_value then
					l_attrs_obj := l_attrs_obj.put_value (l_value, l_attrs_iter.key)
				end
				l_attrs_iter.forth
			end
			Result := Result.put_object (l_attrs_obj, "attributes")
		ensure
			result_not_void: Result /= Void
			has_message_id: Result.has_key ("message_id")
			has_timestamp: Result.has_key ("timestamp")
			has_type: Result.has_key ("type")
		end

	to_binary: ARRAY [NATURAL_8]
			-- Serialize message to binary format (4-byte length prefix + JSON payload).
		require
			is_frozen: is_frozen  -- Message must be immutable before serializing
		local
			l_json: SIMPLE_JSON_OBJECT
			l_json_string: STRING_8
			l_payload: ARRAY [NATURAL_8]
			l_length: INTEGER
			l_i: INTEGER
			l_result: ARRAY [NATURAL_8]
		do
			-- Serialize to JSON
			l_json := to_json
			l_json_string := l_json.as_json

			-- Convert JSON string to byte array
			create l_payload.make_filled (0, 1, l_json_string.count)
			across l_json_string as c loop
				l_payload [l_i + 1] := c.item.code.to_natural_8
				l_i := l_i + 1
			end

			-- Create frame with 4-byte length prefix
			l_length := l_payload.count
			create l_result.make_filled (0, 1, 4 + l_length)

			-- Encode length as big-endian (4 bytes)
			l_result [1] := ((l_length |>> 24) & 0xFF).to_natural_8
			l_result [2] := ((l_length |>> 16) & 0xFF).to_natural_8
			l_result [3] := ((l_length |>> 8) & 0xFF).to_natural_8
			l_result [4] := (l_length & 0xFF).to_natural_8

			-- Copy payload
			from l_i := 1
			until l_i > l_length
			loop
				l_result [4 + l_i] := l_payload [l_i]
				l_i := l_i + 1
			end

			Result := l_result
		ensure
			result_not_void: Result /= Void
			result_not_empty: Result.count > 4
		end

invariant
	message_id_set: message_id /= Void and then message_id.count > 0
	attributes_not_void: attributes /= Void
	timestamp_set: timestamp /= Void
	frozen_is_boolean: True  -- is_frozen is always either True or False

end
