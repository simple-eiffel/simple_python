note
	description: "Tests for IPC_PYTHON_BRIDGE"
	author: "Simple Eiffel Contributors"
	date: "2026-01-28"
	license: "MIT"

class TEST_IPC_PYTHON_BRIDGE

inherit
	EQA_TEST_SET

feature -- Tests

	test_make_creates_unconfigured_bridge
			-- Test that make_with_pipe_name creates unconfigured bridge.
		local
			l_bridge: IPC_PYTHON_BRIDGE
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\eiffel_validator")
			assert ("pipe name set", l_bridge.pipe_name.same_string ("\\.\\pipe\\eiffel_validator"))
			assert ("timeout default", l_bridge.timeout_ms = 5000)
			assert ("not initialized", not l_bridge.is_initialized)
			assert ("no error", not l_bridge.has_error)
		end

	test_set_timeout_updates_timeout
			-- Test that set_timeout updates timeout value.
		local
			l_bridge: IPC_PYTHON_BRIDGE
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\test")
			l_bridge.set_timeout (10000)
			assert ("timeout updated", l_bridge.timeout_ms = 10000)
		end

	test_close_disconnects_bridge
			-- Test that close sets is_connected to False.
		local
			l_bridge: IPC_PYTHON_BRIDGE
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\test")
			l_bridge.close
			assert ("not connected", not l_bridge.is_connected)
		end

	test_encode_frame_adds_length_prefix
			-- Test that encode_frame prepends 4-byte length.
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_payload: ARRAY [NATURAL_8]
			l_frame: ARRAY [NATURAL_8]
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\test")
			create l_payload.make_filled (0, 1, 10)
			l_frame := l_bridge.encode_frame (l_payload)
			assert ("frame not void", l_frame /= Void)
			assert ("frame size correct", l_frame.count = 4 + 10)
			assert ("first 4 bytes are length", l_frame [1] = 0 and l_frame [2] = 0 and l_frame [3] = 0 and l_frame [4] = 10)
		end

	test_decode_frame_extracts_payload
			-- Test that decode_frame extracts payload after length prefix.
		local
			l_bridge: IPC_PYTHON_BRIDGE
			l_payload: ARRAY [NATURAL_8]
			l_frame: ARRAY [NATURAL_8]
			l_extracted: detachable ARRAY [NATURAL_8]
		do
			create l_bridge.make_with_pipe_name ("\\.\\pipe\\test")
			create l_payload.make_filled (42, 1, 10)
			l_frame := l_bridge.encode_frame (l_payload)
			l_extracted := l_bridge.decode_frame (l_frame)
			assert ("extracted not void", l_extracted /= Void)
			if attached l_extracted then
				assert ("extracted size correct", l_extracted.count = 10)
				assert ("extracted payload correct", l_extracted [1] = 42)
			end
		end

end
