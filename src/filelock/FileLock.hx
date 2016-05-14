package filelock;

import haxe.Timer;

using tink.CoreApi;

class FileLock {
	
	public static function lock(path:String, ?options:LockOptions):Surprise<FileLockObject, Error> {
		
		if(options == null) options = {};
		if(options.retryCount == null) options.retryCount = 10;
		if(options.retryInterval == null) options.retryInterval = 100;
		
		var lock =
			#if (nodejs || python || php)
				new FdFileLock(path);
			#elseif java
				new JavaFileLock(path);
			#elseif cs
				new CSharpFileLock(path);
			#end
		
		return lock.lock(options) >> function(_):FileLockObject return lock;
	}
}

typedef LockOptions = {
	?retryCount:Int,
	?retryInterval:Int, // ms
}

interface FileLockObject {
	function lock(options:LockOptions):Surprise<Noise, Error>;
	function unlock():Void;
}

#if (nodejs || python || php)
class FdFileLock implements FileLockObject {
	var path:String;
	var fd:Int;
	
	public function new(path:String) {
		this.path = path;
	}
	
	public function lock(options:LockOptions) {
		return Future.async(function(cb) {
			var trials = 0;
			var lockfilePath = path + '.lock';
			
			function tryOpen() {
				try {
						fd = open(lockfilePath);
						cb(Success(Noise));
				} catch (e:Dynamic) {
					if(trials++ > options.retryCount)
						cb(Failure(new Error('Maximum number of retry')));
					else
						Timer.delay(tryOpen, options.retryInterval);
				}
			}
			
			tryOpen();
			
		});
	}
	
	public function unlock() {
		if(fd == -1) return;
		var lockfilePath = path + '.lock';
		close(fd);
		unlink(lockfilePath);
		fd = -1;
	}
	
	inline function open(path:String):Int {
		#if python
			return python.Syntax.pythonCode("{0}.open({1}, {0}.O_CREAT | {0}.O_EXCL | {0}.O_RDWR)", python.lib.Os, path);
		#elseif nodejs
			var c = js.node.Constants;
			var flags = untyped c.O_CREAT | c.O_EXCL | c.O_RDWR;
			return js.node.Fs.openSync(path, flags);
		#elseif php
			var r:Dynamic = untyped __call__('fopen', path, 'x');
			if(!r) throw "Cannot open";
			return r;
		#end
	}
	
	inline function close(fd:Int) {
		#if python
			return python.Syntax.pythonCode("{0}.close({1})", python.lib.Os, fd);
		#elseif nodejs
			js.node.Fs.closeSync(fd);
		#elseif php
			untyped __call__('fclose', fd);
		#end
	}
	
	inline function unlink(path:String) {
		#if python
			python.Syntax.pythonCode("{0}.unlink({1})", python.lib.Os, path);
		#elseif nodejs
			js.node.Fs.unlinkSync(path);
		#elseif php
			untyped __call__('unlink', path);
		#end
	}
}
#end

#if java
class JavaFileLock implements FileLockObject {
	
	var path:String;
	var channel:java.nio.channels.FileChannel;
	var nativeLock:java.nio.channels.FileLock;
	
	public function new(path) {
		this.path = path;
	}
	
	
	public function lock(options) {
		return Future.async(function(cb) {
			var trials = 0;
			var file = new java.io.File(path);
			
			try
				channel = new java.io.RandomAccessFile(file, 'rw').getChannel()
			catch(e:Dynamic) {
				cb(Failure(Error.withData('Error in creating RandomAccessFile', e)));
				return;
			}
			
			function tryLock() {
				try {
					nativeLock = channel.tryLock();
					cb(Success(Noise));
				} catch (e:Dynamic) {
					if(trials++ > options.retryCount)
						cb(Failure(new Error('Maximum number of retry')));
					else
						Timer.delay(tryLock, options.retryInterval);
				}
			}
			
			tryLock();
			
		});
	}
	
	public function unlock() {
		if(nativeLock == null) return;
		nativeLock.release();
		channel.close();
		nativeLock = null;
	}
}
#end

#if cs

class CSharpFileLock implements FileLockObject {
	
	var path:String;
	var fileStream:cs.system.io.FileStream;
	
	public function new(path) {
		this.path = path;
	}
	
	public function lock(options) {
		return Future.async(function(cb) {
			
			var trials = 0;
			
			function tryLock() {
				try {
					fileStream = new cs.system.io.FileStream(path + '.lock', cs.system.io.FileMode.CreateNew);
					cb(Success(Noise));
				} catch (e:Dynamic) {
					if(trials++ > options.retryCount)
						cb(Failure(new Error('Maximum number of retry')));
					else
						Timer.delay(tryLock, options.retryInterval);
				}
			}
			
			tryLock();
			
		});
	}
	
	public function unlock() {
		if(fileStream == null) return;
		fileStream.Close();
		fileStream = null;
		cs.system.io.File.Delete(path + '.lock');
	}
}

#end