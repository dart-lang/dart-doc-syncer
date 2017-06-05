import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

/// Global options
class Options {
  String branch = 'master';
  bool dryRun = true;
  bool forceBuild = false;
  bool keepTmp = false;
  bool push = true;
  /*@nullable*/ RegExp match;
  String user = 'dart-lang';
  bool verbose = false;
  // Usage help text generated by arg parser
  String usage = '';
}

Options options = new Options();

// TODO: make these configurable? (with defaults as given)
const dartDocHostUri = 'https://webdev.dartlang.org';
const dartDocUriPrefix = dartDocHostUri + '/angular';
const exampleConfigFileName = '.docsync.json';
const exampleHostUriPrefix = '$dartDocHostUri/examples/ng/doc';
const tempFolderNamePrefix = 'dds-';

Directory initWorkingDir() {
  final tmpEnvVar = Platform.environment['TMP'];
  if (tmpEnvVar != null) {
    final dir = new Directory(tmpEnvVar);
    if (dir.existsSync()) return dir;
  }
  return Directory.systemTemp;
}

Directory workDir = initWorkingDir().createTempSync(tempFolderNamePrefix);

const Map<String, String> _help = const {
  'branch': '<branch-name>\ngit branch to fetch examples from',
  'dry-run': 'show which commands would be executed but make (almost) '
      'no changes;\nonly the temporary directory will be created',
  'force-build': 'forces build of example app when sources have not changed',
  'help': 'show this usage information',
  'keep-tmp':
      'do not delete temporary working directory once done',
  'push': 'prepare updates and push to example repo',
  'match': '<dart-regexp>\n'
      'sync all examples having a data file ($exampleConfigFileName)\n'
      'and whose repo path matches the given regular expression;\n'
      'use "." to match all',
  'user': '<user-id>\nGitHub id of repo to fetch examples from',
};

/// Processes command line options and returns remaining arguments.
List<String> processArgs(List<String> args) {
  ArgParser argParser = new ArgParser(allowTrailingOptions: true);

  argParser.addFlag('help', abbr: 'h', negatable: false, help: _help['help']);
  argParser.addOption('branch',
      abbr: 'b', help: _help['branch'], defaultsTo: options.branch);
  argParser.addFlag('dry-run',
      abbr: 'n', negatable: false, help: _help['dry-run']);
  argParser.addFlag('force-build',
      abbr: 'f', negatable: false, help: _help['force-build']);
  argParser.addFlag('keep-tmp',
      abbr: 'k', negatable: false, help: _help['keep-tmp']);
  argParser.addFlag('push',
      abbr: 'p', help: _help['push'], defaultsTo: options.push);
  argParser.addOption('match', abbr: 'm', help: _help['match']);
  argParser.addOption('user',
      abbr: 'u', help: _help['user'], defaultsTo: options.user);
  argParser.addFlag('verbose',
      abbr: 'v', negatable: false, defaultsTo: options.verbose);

  var argResults;
  try {
    argResults = argParser.parse(args);
  } on FormatException catch (e) {
    printUsageAndExit(e.message, 0);
  }

  options.usage = argParser.usage;
  if (argResults['help']) printUsageAndExit();

  options
    ..branch = argResults['branch']
    ..dryRun = argResults['dry-run']
    ..forceBuild = argResults['force-build']
    ..keepTmp = argResults['keep-tmp']
    ..push = argResults['push']
    ..match =
        argResults['match'] != null ? new RegExp(argResults['match']) : null
    ..user = argResults['user']
    ..verbose = argResults['verbose'];

  return argResults.rest;
}

void printUsageAndExit([String _msg, int exitCode = 1]) {
  var msg = 'Syncs Angular docs example applications.';
  if (_msg != null) msg = _msg;
  print('''

$msg.

Usage: ${p.basenameWithoutExtension(Platform.script.path)} [options] [<exampleName> | <examplePath> <exampleRepo>]

${options.usage}
''');
  exit(exitCode);
}
