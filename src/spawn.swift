import LibUV
import Darwin

typealias UVLoopPtr = UnsafeMutablePointer<uv_loop_t>
typealias UVProcessPtr = UnsafeMutablePointer<uv_process_t>
typealias UVProcessOptionsPtr = UnsafeMutablePointer<uv_process_options_t>

class NativeBox<T> {
	let ptr: UnsafeMutablePointer<T>

	init() {
		ptr = UnsafeMutablePointer<T>.alloc(sizeof(T))
	}

	func dealloc() {
		ptr.dealloc(sizeof(T))
	}
}

class AutoNative<T> : NativeBox<T> {
	deinit { dealloc() }
}

class Loop {
	let loopRef: UVLoopPtr

	static var uvDefault = Loop(loopRef: uv_default_loop())

	init(loopRef: UVLoopPtr) {
		self.loopRef = loopRef
	}

	func run() {
		uv_run(loopRef, UV_RUN_DEFAULT)
	}

	deinit {
		uv_loop_close(loopRef)
		loopRef.dealloc(sizeof(uv_loop_t))
	}
}

func toIntPtr(s: String) -> UnsafeMutablePointer<Int8> { return strdup(s) }

func spawn(args: [String]) {
	let process = NativeBox<uv_process_t>()
	let options = NativeBox<uv_process_options_t>()

	var cArgs = args.map(toIntPtr)
	cArgs.append(nil)

	options.ptr.memory.args = UnsafeMutablePointer(cArgs)
	options.ptr.memory.file = UnsafePointer(toIntPtr(args[0]))

	options.ptr.memory.exit_cb = { req, status, _ in
		uv_close(UnsafeMutablePointer(req), nil)
	}

	let result = uv_spawn(Loop.uvDefault.loopRef, process.ptr, options.ptr)

	if(result < 0) {
		print(String.fromCString(uv_strerror(result)) ?? "unknown error")
	}

	options.dealloc()
}

spawn(["touch", "hello"])
Loop.uvDefault.run()
