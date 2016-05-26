# filelock

Lock a file and prevents it from being accessed by others

## Targets

At the moment only C++, Python, Java, NodeJS & PHP.
But should be extendable to other targets.

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
