// ignore_for_file: avoid_print

import 'dart:io';

void main(List<String> arguments) async {
  // Directory to scan (use current directory by default, or pass as argument)
  final String targetDir = arguments.isNotEmpty ? arguments[0] : '.';
  final String outputFile = 'dart_files_combined.txt';

  final Directory directory = Directory(targetDir);

  // Check if directory exists
  if (!await directory.exists()) {
    print('Error: Directory "$targetDir" does not exist.');
    return;
  }

  // Create or clear the output file
  final File output = File(outputFile);
  await output.create(recursive: true);
  await output.writeAsString(''); // Clear the file

  print('Scanning directory: $targetDir');
  print('Output file: $outputFile');

  int fileCount = 0;

  // Recursively get all dart files
  final Stream<FileSystemEntity> entities = directory.list(
    recursive: true,
    followLinks: false,
  );

  await for (final FileSystemEntity entity in entities) {
    if (entity is File) {
      // Get the file path and convert to use consistent separators
      String filePath = entity.path.replaceAll('\\', '/');
      String targetDirPath = targetDir.replaceAll('\\', '/');

      // Check if it's a Dart file
      //!filePath.toLowerCase().contains('node_modules')
      //
      if (filePath.toLowerCase().endsWith('.dart')) {
        // Calculate relative path
        String relativePath;
        if (targetDirPath == '.' || targetDirPath.isEmpty) {
          relativePath = filePath;
        } else {
          // Remove the target directory prefix
          if (filePath.startsWith('$targetDirPath/')) {
            relativePath = filePath.substring(targetDirPath.length + 1);
          } else {
            relativePath = filePath;
          }
        }

        final String fileContent = await entity.readAsString();

        // Append to output file with path comment
        await output.writeAsString(
          '// File: $relativePath\n'
          '$fileContent\n\n'
          '//------------------------------------------------------------------------------\n\n',
          mode: FileMode.append,
        );

        fileCount++;
        print('Processed: $relativePath');
      }
    }
  }

  print('\nDone! Processed $fileCount Dart files.');
  print('Combined output saved to: $outputFile');
}


// dart accumilator.dart functions/src