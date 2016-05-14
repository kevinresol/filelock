package filelock;

import haxe.Timer;

using tink.CoreApi;

class FileLock {
	
	public static function lock(path:String, ?options:LockOptions):Surprise<FileLockObject, Error> {
		
		if(options == null) options = {};
		if(options.retryCount == null) options.retryCount = 10;
		if(options.retryInterval == null) options.retryInterval = 100;
		
		var lock = new FileLockObject(path);
		
		return lock.lock(options) >> function(_) return lock;
	}
}

typedef LockOptions = {
	?retryCount:Int,
	?retryInterval:Int, // ms
}

class FileLockObject {
	
	var path:String;
	var lockFilePath(get, never):String;
	
	public function new(path:String) {
		this.path = path;
	}
	
	public function lock(options:LockOptions) {
		return Future.async(function(cb) {
			var trials = 0;
			
			function tryCreate() {
				try {
					// platform-specific atomic file creation, which should fail if file already exists
					#if python
						var fd = python.Syntax.pythonCode("{0}.open({1}, {0}.O_CREAT | {0}.O_EXCL | {0}.O_RDWR)", python.lib.Os, lockFilePath);
						python.Syntax.pythonCode("{0}.close({1})", python.lib.Os, fd);
					#elseif nodejs
						var c = js.node.Constants;
						var fd = js.node.Fs.openSync(lockFilePath, untyped c.O_CREAT | c.O_EXCL | c.O_RDWR);
						js.node.Fs.closeSync(fd);
					#elseif php
						var r:Dynamic = untyped __call__('fopen', lockFilePath, 'x');
						if(!r) throw "Cannot create lock file";
						untyped __call__('fclose', r);
					#elseif java
						var r = new java.io.File(lockFilePath).createNewFile();
						if(!r) throw "Cannot create lock file";
					#elseif cs
						var fileStream = new cs.system.io.FileStream(path + '.lock', cs.system.io.FileMode.CreateNew);
						fileStream.Close();
					#elseif cpp
						var fd = CppIo.open(lockFilePath, 0x0200 | 0x0800 | 0x0002); // O_CREAT | O_EXCL | O_RDWR
						if(fd == -1) throw "Cannot create lock file";
						CppIo.close(fd);
					#end
						
					cb(Success(Noise));
				} catch (e:Dynamic) {
					if(trials++ > options.retryCount)
						cb(Failure(new Error('Maximum number of retry')));
					else
						Timer.delay(tryCreate, options.retryInterval);
				}
			}
			
			tryCreate();
			
		});
	}
	
	public function unlock() {
		sys.FileSystem.deleteFile(lockFilePath);
	}
	
	inline function get_lockFilePath() return '$path.lock';
}

#if cpp

// @:include("sys/stat.h")
@:include("fcntl.h")
extern class CppIo {
	@:native("open")
	public static function open(path:String, flags:Int):Int;
	@:native("close")
	public static function close(fd:Int):Void;
}
#end