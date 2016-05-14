package;

import haxe.Timer;
import filelock.FileLock;
import buddy.*;
using buddy.Should;
using sys.io.File;
using sys.FileSystem;

class RunTests extends BuddySuite {
	
	static inline var TEST_FILE = 'test.txt';
	
	static function main() {
		var reporter = new buddy.reporting.ConsoleReporter();
		
		var runner = new buddy.SuitesRunner([
			new RunTests(),
		], reporter);
		
		runner.run().then(function(_) {
			Sys.exit(runner.failed() ? 500 : 0);
		});
	}
	
	public function new() {
		describe("Test File Lock", {
			it("should lock and release", function(done) {
				TEST_FILE.saveContent('1');
				
				FileLock.lock(TEST_FILE).handle(function(o) switch o {
					case Success(lock):
						Timer.delay(function() {
							TEST_FILE.getContent().should.be('1');
							TEST_FILE.saveContent('2');
							lock.unlock();
						}, 500);
					case Failure(f):
						fail(f);
				});
				
				FileLock.lock(TEST_FILE).handle(function(o) switch o {
					case Success(lock):
						TEST_FILE.getContent().should.be('2');
						lock.unlock();
						TEST_FILE.deleteFile();
						done();
					case Failure(f):
						fail(f);
				});
			});
			
			it("should lock and fail to acquire due to timeout", function(done) {
				TEST_FILE.saveContent('1');
				
				FileLock.lock(TEST_FILE).handle(function(o) switch o {
					case Success(lock):
						Timer.delay(function() {
							TEST_FILE.getContent().should.be('1');
							lock.unlock();
							TEST_FILE.deleteFile();
							done();
						}, 1500);
					case Failure(f):
						fail(f);
				});
				
				FileLock.lock(TEST_FILE).handle(function(o) switch o {
					case Success(_):
						fail('should fail after max retries');
						
					case Failure(f):
						
						
				});
			});
		});
	}
}