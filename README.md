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
		lock.unlock;
	case Failure(err):
		trace(err)
});
```