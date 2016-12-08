# filelock

A little utility that helps preventing concurrent access of a file.

## Targets

Currently supports python, nodejs, php, java, c#, c++, neko. 

Support for other platform? PR please =)

## Usage

```haxe
FileLock.lock('my_file.txt').handle(function(o) switch o {
	case Success(lock):
		// do your work here
		lock.unlock();
	case Failure(err):
		trace(err)
});
```

## Implementation

A `.lock` file is created when `FileLock.lock()` acquires the file lock.
If the `.lock` file already exists, it means that the file has been locked by someone else.
`FileLock.lock()` will keep trying to acquire the lock until it fails when 
the specified number of retries reached.

Note that the original file is NOT actually locked from any read/write operation.

## TODO

Staled/expired lock
