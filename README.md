# webidl2swift

Generate Swift bridging code from Web IDL files.

## Requirements

This tool currently only runs on macOS and requires Xcode.app.

## Installation

The tool can be build using `swift build`.

## Usage

```
USAGE: generate-code --input-directory <input-directory> --ouput-directory <ouput-directory> [--create-separate-files] [--no-create-separate-files] [--verbose] [--pretty-print] [--no-pretty-print]

OPTIONS:
  -i, --input-directory <input-directory>
                          The path to the directory containing Web IDL files. 
  -o, --ouput-directory <ouput-directory>
                          The path to the output directory. 
  --create-separate-files/--no-create-separate-files
                          Create a file for each definition. (default: true)
  --verbose               Print verbose output. 
  --pretty-print/--no-pretty-print
                          Run swift-format over output. (default: true)
  -h, --help              Show help information.
```

For an example setup, see [Example](https://github.com/Apodini/webidl2swift/tree/develop/Example)

## Contributing
Contributions to this projects are welcome. Please make sure to read the [contribution guidelines](https://github.com/Apodini/.github/blob/master/CONTRIBUTING.md) first.

## License
This project is licensed under the MIT License. See [License](https://github.com/Apodini/webidl2swift/blob/master/LICENSE) for more information.
